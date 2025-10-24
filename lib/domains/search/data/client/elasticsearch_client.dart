import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/search_result.dart';
import '../../../../core/functions/functions_client.dart';

/// Elasticsearch client for hybrid search (keyword + semantic)
///
/// Uses Appwrite Functions proxy to avoid CORS issues in web deployment
class ElasticsearchClient {
  final String endpoint;
  final String apiKey;
  final String indexName;
  final FunctionsClient? functionsClient; // Optional: use for web/proxy mode

  ElasticsearchClient({
    required this.endpoint,
    required this.apiKey,
    this.indexName = 'pubmed_articles',
    this.functionsClient, // Pass this to enable proxy mode
  });

  /// Perform hybrid search (keyword + semantic vector search)
  /// Combines BM25 keyword search with kNN vector search using RRF
  Future<SearchResults> hybridSearch({
    required String query,
    List<double>? queryEmbedding,
    int size = 10,
    Map<String, dynamic>? filters,
    double keywordWeight = 0.5,
    double vectorWeight = 0.5,
  }) async {
    final startTime = DateTime.now();

    // Build hybrid search query using RRF (Reciprocal Rank Fusion)
    final searchBody =
        queryEmbedding != null
            ? _buildHybridSearchQuery(
              query: query,
              queryEmbedding: queryEmbedding,
              size: size,
              filters: filters,
            )
            : _buildKeywordSearchQuery(
              query: query,
              size: size,
              filters: filters,
            );

    final response = await _post('/$indexName/_search', searchBody);

    if (response.statusCode != 200) {
      throw Exception(
        'Search failed (${response.statusCode}): ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final hits = (data['hits']?['hits'] as List?) ?? [];
    final totalHits = (data['hits']?['total']?['value'] as int?) ?? hits.length;

    final results =
        hits.map((hit) {
          final source = (hit['_source'] as Map<String, dynamic>?) ?? {};
          final id = source['pmid']?.toString() ?? hit['_id']?.toString() ?? '';

          return SearchResult(
            id: id,
            title: source['title']?.toString() ?? '',
            abstract: source['abstract']?.toString() ?? '',
            score: (hit['_score'] as num?)?.toDouble() ?? 0.0,
            publicationDate:
                source['publication_date'] != null
                    ? DateTime.tryParse(source['publication_date'].toString())
                    : null,
            sourceUrl:
                source['source_url']?.toString() ??
                'https://pubmed.ncbi.nlm.nih.gov/$id/',
            authors: (source['authors'] as List?)?.cast<String>() ?? [],
            metadata: source,
          );
        }).toList();

    final searchTime = DateTime.now().difference(startTime);

    return SearchResults(
      results: results,
      totalHits: totalHits,
      searchTime: searchTime,
      query: query,
    );
  }

  /// Index a single document
  Future<void> indexDocument(Map<String, dynamic> document) async {
    final pmid = document['pmid'];
    if (pmid == null) {
      throw Exception('Document must have a pmid field');
    }

    final response = await _put('/$indexName/_doc/$pmid', document);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Indexing failed: ${response.body}');
    }
  }

  /// Bulk index documents (efficient for large datasets)
  Future<Map<String, dynamic>> bulkIndex(
    List<Map<String, dynamic>> documents,
  ) async {
    if (documents.isEmpty) {
      return {'indexed': 0, 'errors': 0};
    }

    // Build NDJSON format for bulk API
    final ndjson = StringBuffer();
    for (final doc in documents) {
      final pmid = doc['pmid'];
      if (pmid == null) continue;

      // Index action
      ndjson.writeln(
        jsonEncode({
          'index': {'_index': indexName, '_id': pmid},
        }),
      );
      // Document
      ndjson.writeln(jsonEncode(doc));
    }

    final response = await _post('/_bulk', ndjson.toString(), isNdjson: true);

    if (response.statusCode != 200) {
      throw Exception('Bulk indexing failed: ${response.body}');
    }

    final result = jsonDecode(response.body) as Map<String, dynamic>;
    final hasErrors = result['errors'] == true;

    int indexed = 0;
    int errors = 0;

    if (hasErrors) {
      final items = result['items'] as List? ?? [];
      for (final item in items) {
        final indexResult = item['index'] as Map<String, dynamic>? ?? {};
        if (indexResult['error'] != null) {
          errors++;
        } else {
          indexed++;
        }
      }
    } else {
      indexed = documents.length;
    }

    return {'indexed': indexed, 'errors': errors};
  }

  /// Create index with mapping for medical articles
  Future<void> createIndex() async {
    final mapping = {
      'mappings': {
        'properties': {
          'pmid': {'type': 'keyword'},
          'title': {
            'type': 'text',
            'analyzer': 'english',
            'fields': {
              'keyword': {'type': 'keyword'},
            },
          },
          'abstract': {'type': 'text', 'analyzer': 'english'},
          'content': {'type': 'text', 'analyzer': 'english'},
          'publication_date': {'type': 'date'},
          'authors': {'type': 'keyword'},
          'source_url': {'type': 'keyword'},
          'article_type': {'type': 'keyword'},
          // Vector field for semantic search (will be used when we add embeddings)
          'embedding': {
            'type': 'dense_vector',
            'dims': 768,
            'index': true,
            'similarity': 'cosine',
          },
        },
      },
      'settings': {
        'number_of_shards': 1,
        'number_of_replicas': 1,
        'index': {'max_result_window': 10000},
      },
    };

    final response = await _put('/$indexName', mapping);

    if (response.statusCode == 200 || response.statusCode == 201) {
      debugPrint('✅ Index "$indexName" created successfully');
    } else if (response.statusCode == 400 &&
        response.body.contains('resource_already_exists')) {
      debugPrint('ℹ️  Index "$indexName" already exists');
    } else {
      throw Exception('Index creation failed: ${response.body}');
    }
  }

  /// Check if index exists
  Future<bool> indexExists() async {
    final response = await _head('/$indexName');
    return response.statusCode == 200;
  }

  /// Delete index (useful for testing/reset)
  Future<void> deleteIndex() async {
    final response = await _delete('/$indexName');
    if (response.statusCode == 200) {
      debugPrint('✅ Index "$indexName" deleted');
    } else {
      debugPrint('⚠️  Failed to delete index: ${response.body}');
    }
  }

  /// Get index stats (document count, size, etc.)
  Future<Map<String, dynamic>> getIndexStats() async {
    final response = await _get('/$indexName/_stats');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final indices = data['indices'] as Map<String, dynamic>? ?? {};
      final indexData = indices[indexName] as Map<String, dynamic>? ?? {};
      final total = indexData['total'] as Map<String, dynamic>? ?? {};
      final docs = total['docs'] as Map<String, dynamic>? ?? {};

      return {
        'document_count': docs['count'] ?? 0,
        'deleted_count': docs['deleted'] ?? 0,
        'size_in_bytes':
            (total['store'] as Map<String, dynamic>?)?['size_in_bytes'] ?? 0,
      };
    }
    return {};
  }

  /// Test connection to Elasticsearch
  Future<bool> testConnection() async {
    try {
      final response = await _get('/');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Connected to Elasticsearch ${data['version']['number']}');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Connection failed: $e');
      return false;
    }
  }

  // ========== HTTP Helper Methods ==========

  Future<http.Response> _get(String path) async {
    final url = Uri.parse('$endpoint$path');
    return http.get(url, headers: _headers);
  }

  Future<http.Response> _post(
    String path,
    dynamic body, {
    bool isNdjson = false,
  }) async {
    // Use Appwrite Functions proxy if available (for web/CORS issues)
    if (functionsClient != null && path.contains('/_search')) {
      try {
        final requestBody = body is String ? jsonDecode(body) : body;

        final result = await functionsClient!.execJson(
          method: 'POST',
          path: '/search',
          data: requestBody as Map<String, dynamic>,
        );

        // Extract the data from SecureAPI response format
        // SecureAPI wraps responses as: {status, message, data}
        // FunctionsClient.execJson() already returns a decoded Map
        final data = result['data'] ?? result;

        // Validate we have Elasticsearch response structure
        if (data is! Map<String, dynamic>) {
          throw Exception('Invalid Elasticsearch response type');
        }

        if (!data.containsKey('hits')) {
          throw Exception('Invalid Elasticsearch response structure');
        }

        // Since data is already a Map, encode it ONCE to a JSON string for http.Response.body
        final responseBody = jsonEncode(data);

        // Return the response - http.Response.body expects a String
        return http.Response(
          responseBody,
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      } catch (e) {
        debugPrint('❌ Elasticsearch proxy error: $e');

        // Return error response
        return http.Response(
          jsonEncode({'error': e.toString()}),
          500,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }
    }

    // Fallback to direct HTTP (for non-web or when functionsClient not provided)
    final url = Uri.parse('$endpoint$path');
    return http.post(
      url,
      headers: {
        ..._headers,
        'Content-Type': isNdjson ? 'application/x-ndjson' : 'application/json',
      },
      body: body is String ? body : jsonEncode(body),
    );
  }

  Future<http.Response> _put(String path, dynamic body) async {
    final url = Uri.parse('$endpoint$path');
    return http.put(
      url,
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: body is String ? body : jsonEncode(body),
    );
  }

  Future<http.Response> _delete(String path) async {
    final url = Uri.parse('$endpoint$path');
    return http.delete(url, headers: _headers);
  }

  Future<http.Response> _head(String path) async {
    final url = Uri.parse('$endpoint$path');
    return http.head(url, headers: _headers);
  }

  Map<String, String> get _headers => {'Authorization': 'ApiKey $apiKey'};

  /// Build hybrid search query with RRF
  Map<String, dynamic> _buildHybridSearchQuery({
    required String query,
    required List<double> queryEmbedding,
    required int size,
    Map<String, dynamic>? filters,
  }) {
    // For Elasticsearch 8.x, use knn with boost parameter
    // This combines vector and keyword search scores
    final filterClause =
        filters != null && filters.isNotEmpty ? _buildFilters(filters) : null;

    return {
      'size': size,
      'query': {
        'bool': {
          'should': [
            // Keyword search component (BM25)
            {
              'multi_match': {
                'query': query,
                'fields': ['title^3', 'abstract^2', 'content'],
                'type': 'best_fields',
                'fuzziness': 'AUTO',
                'boost': 1.0,
              },
            },
          ],
          if (filterClause != null) 'filter': filterClause,
        },
      },
      // Vector search using kNN (will be combined with query scores)
      'knn': {
        'field': 'embedding',
        'query_vector': queryEmbedding,
        'k': size * 2, // Retrieve more candidates
        'num_candidates': 100,
        'boost': 1.0, // Equal weight with keyword search
        if (filterClause != null)
          'filter': {
            'bool': {'filter': filterClause},
          },
      },
      '_source': [
        'pmid',
        'title',
        'abstract',
        'publication_date',
        'authors',
        'source_url',
        'article_type',
        'publicationType',
      ],
      'highlight': {
        'fields': {
          'abstract': {'fragment_size': 150, 'number_of_fragments': 3},
          'title': {},
        },
        'pre_tags': ['<mark>'],
        'post_tags': ['</mark>'],
      },
    };
  }

  /// Build keyword-only search query (fallback when no embeddings)
  Map<String, dynamic> _buildKeywordSearchQuery({
    required String query,
    required int size,
    Map<String, dynamic>? filters,
  }) {
    return {
      'query': {
        'bool': {
          'must': [
            {
              'multi_match': {
                'query': query,
                'fields': ['title^3', 'abstract^2', 'content'],
                'type': 'best_fields',
                'fuzziness': 'AUTO',
              },
            },
          ],
          if (filters != null && filters.isNotEmpty)
            'filter': _buildFilters(filters),
        },
      },
      'size': size,
      '_source': [
        'pmid',
        'title',
        'abstract',
        'publication_date',
        'authors',
        'source_url',
        'article_type',
        'publicationType',
      ],
      'highlight': {
        'fields': {
          'abstract': {'fragment_size': 150, 'number_of_fragments': 3},
          'title': {},
        },
        'pre_tags': ['<mark>'],
        'post_tags': ['</mark>'],
      },
    };
  }

  /// Get a document by its ID (PMID)
  Future<Map<String, dynamic>?> getDocumentById(String id) async {
    try {
      // Use Appwrite Functions proxy if available (for web/CORS issues)
      if (functionsClient != null) {
        try {
          final result = await functionsClient!.execJson(
            method: 'GET',
            path: '/doc/$id',
          );

          final data = result['data'] ?? result;

          if (data is! Map<String, dynamic>) {
            return null;
          }

          // Elasticsearch wraps the document in {_source: {...}}
          return data['_source'] as Map<String, dynamic>?;
        } catch (e) {
          debugPrint('❌ Error fetching document via proxy: $e');
          return null;
        }
      }

      // Fallback to direct HTTP
      final response = await _get('/$indexName/_doc/$id');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['_source'] as Map<String, dynamic>?;
      } else if (response.statusCode == 404) {
        // Document not found
        return null;
      } else {
        throw Exception(
          'Failed to get document (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('Error fetching document by ID: $e');
      return null;
    }
  }

  /// Build Elasticsearch filter clauses from filter map
  List<Map<String, dynamic>> _buildFilters(Map<String, dynamic> filters) {
    final filterList = <Map<String, dynamic>>[];

    filters.forEach((key, value) {
      if (value != null) {
        if (value is Map &&
            (value.containsKey('gte') || value.containsKey('lte'))) {
          // Date range filter
          filterList.add({
            'range': {key: value},
          });
        } else {
          // Term filter
          filterList.add({
            'term': {key: value},
          });
        }
      }
    });

    return filterList;
  }
}
