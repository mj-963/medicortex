import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/search_result.dart';
import '../../../../core/functions/functions_client.dart';

/// Qdrant vector database client for hybrid search
/// Replaces Elasticsearch — free tier available at cloud.qdrant.io
///
/// On web, uses an Appwrite Functions proxy to avoid CORS restrictions.
/// On native platforms, calls Qdrant directly.
class QdrantClient {
  final String endpoint;
  final String apiKey;
  final String collectionName;
  final FunctionsClient? functionsClient; // proxy for web

  QdrantClient({
    required this.endpoint,
    required this.apiKey,
    this.collectionName = 'pubmed_articles',
    this.functionsClient,
  });

  /// Perform search:
  ///   - Vector search (semantic) when [queryEmbedding] is provided
  ///   - Text-index scroll (keyword) as fallback
  Future<SearchResults> hybridSearch({
    required String query,
    List<double>? queryEmbedding,
    int size = 10,
    Map<String, dynamic>? filters,
    double keywordWeight = 0.5, // kept for API compatibility
    double vectorWeight = 0.5, // kept for API compatibility
  }) async {
    final startTime = DateTime.now();

    List<dynamic> points;
    int totalHits;

    if (queryEmbedding != null) {
      // Semantic vector search via cosine similarity
      final body = <String, dynamic>{
        'vector': queryEmbedding,
        'limit': size,
        'with_payload': true,
        'score_threshold': 0.0,
      };
      if (filters != null && filters.isNotEmpty) {
        body['filter'] = _buildFilter(filters);
      }

      final response = await _post(
        '/collections/$collectionName/points/search',
        body,
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Qdrant search failed (${response.statusCode}): ${response.body}',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      points = (data['result'] as List?) ?? [];
      totalHits = points.length;
    } else {
      // Keyword fallback via payload text index (requires text index on 'content')
      final mustClauses = <Map<String, dynamic>>[
        {
          'key': 'content',
          'match': {'text': query},
        },
      ];
      if (filters != null && filters.isNotEmpty) {
        mustClauses.addAll(_buildFilterClauses(filters));
      }

      final body = <String, dynamic>{
        'filter': {'must': mustClauses},
        'limit': size,
        'with_payload': true,
        'with_vector': false,
      };

      final response = await _post(
        '/collections/$collectionName/points/scroll',
        body,
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Qdrant scroll failed (${response.statusCode}): ${response.body}',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      points = (data['result']?['points'] as List?) ?? [];
      totalHits = points.length;
    }

    final results =
        points.map((point) {
          final payload = (point['payload'] as Map<String, dynamic>?) ?? {};
          final id =
              payload['pmid']?.toString() ?? point['id']?.toString() ?? '';
          final score = (point['score'] as num?)?.toDouble() ?? 0.0;

          return SearchResult(
            id: id,
            title: payload['title']?.toString() ?? '',
            abstract: payload['abstract']?.toString() ?? '',
            score: score,
            publicationDate:
                payload['publication_date'] != null
                    ? DateTime.tryParse(payload['publication_date'].toString())
                    : null,
            sourceUrl:
                payload['source_url']?.toString() ??
                'https://pubmed.ncbi.nlm.nih.gov/$id/',
            authors: (payload['authors'] as List?)?.cast<String>() ?? [],
            metadata: payload,
          );
        }).toList();

    return SearchResults(
      results: results,
      totalHits: totalHits,
      searchTime: DateTime.now().difference(startTime),
      query: query,
    );
  }

  /// Create Qdrant collection with 768-dim cosine vectors + text index
  Future<void> createIndex() async {
    final body = {
      'vectors': {'size': 768, 'distance': 'Cosine'},
      'on_disk_payload': false,
    };

    final response = await _put('/collections/$collectionName', body);

    if (response.statusCode == 200) {
      debugPrint('✅ Qdrant collection "$collectionName" created');
      await _ensureTextIndex();
    } else if (response.statusCode == 409) {
      debugPrint('ℹ️ Qdrant collection "$collectionName" already exists');
    } else {
      throw Exception(
        'Collection creation failed (${response.statusCode}): ${response.body}',
      );
    }
  }

  /// Create text index on `content` field for keyword search fallback
  Future<void> _ensureTextIndex() async {
    final body = {
      'field_name': 'content',
      'field_schema': {
        'type': 'text',
        'tokenizer': 'word',
        'min_token_len': 2,
        'max_token_len': 30,
        'lowercase': true,
      },
    };
    final response = await _put('/collections/$collectionName/index', body);
    if (response.statusCode == 200 || response.statusCode == 202) {
      debugPrint('✅ Text index created on content field');
    }
  }

  /// Check if collection exists
  Future<bool> indexExists() async {
    final response = await _get('/collections/$collectionName');
    return response.statusCode == 200;
  }

  /// Delete collection
  Future<void> deleteIndex() async {
    final response = await _delete('/collections/$collectionName');
    if (response.statusCode == 200) {
      debugPrint('✅ Qdrant collection "$collectionName" deleted');
    } else {
      debugPrint('⚠️ Failed to delete collection: ${response.body}');
    }
  }

  /// Get collection stats (document count, status)
  Future<Map<String, dynamic>> getIndexStats() async {
    final response = await _get('/collections/$collectionName');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final result = (data['result'] as Map<String, dynamic>?) ?? {};
      return {
        'document_count': result['points_count'] ?? result['vectors_count'] ?? 0,
        'status': result['status'] ?? 'unknown',
      };
    }
    return {'document_count': 0};
  }

  /// Test connection to Qdrant cluster
  Future<bool> testConnection() async {
    try {
      final response = await _get('/');
      if (response.statusCode == 200) {
        debugPrint('✅ Connected to Qdrant');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Qdrant connection failed: $e');
      return false;
    }
  }

  /// Get a document by PMID (Qdrant uses uint64 IDs)
  Future<Map<String, dynamic>?> getDocumentById(String id) async {
    try {
      final numId = int.tryParse(id);
      if (numId == null) return null;

      final response = await _post('/collections/$collectionName/points', {
        'ids': [numId],
        'with_payload': true,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final pts = (data['result'] as List?) ?? [];
        if (pts.isEmpty) return null;
        return pts.first['payload'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching document by ID: $e');
      return null;
    }
  }

  // ---- filter builders ----

  Map<String, dynamic> _buildFilter(Map<String, dynamic> filters) {
    return {'must': _buildFilterClauses(filters)};
  }

  List<Map<String, dynamic>> _buildFilterClauses(
    Map<String, dynamic> filters,
  ) {
    final list = <Map<String, dynamic>>[];
    filters.forEach((key, value) {
      if (value == null) return;
      if (value is Map &&
          (value.containsKey('gte') || value.containsKey('lte'))) {
        final range = <String, dynamic>{};
        if (value['gte'] != null) range['gte'] = value['gte'];
        if (value['lte'] != null) range['lte'] = value['lte'];
        list.add({'key': key, 'range': range});
      } else {
        list.add({
          'key': key,
          'match': {'value': value},
        });
      }
    });
    return list;
  }

  // ---- HTTP helpers ----

  Map<String, String> get _headers => {
    'api-key': apiKey,
    'Content-Type': 'application/json',
  };

  Future<http.Response> _get(String path) =>
      http.get(Uri.parse('$endpoint$path'), headers: _headers);

  /// POST — routes through Appwrite Functions proxy on web to avoid CORS.
  /// The proxy function exposes /search, /scroll, and /doc endpoints.
  Future<http.Response> _post(String path, Map<String, dynamic> body) async {
    // Map Qdrant collection paths to the proxy's short paths
    final proxyPath = _toProxyPath(path);
    if (functionsClient != null && proxyPath != null) {
      try {
        final result = await functionsClient!.execJson(
          method: 'POST',
          path: proxyPath,
          data: body,
        );
        return http.Response(
          jsonEncode(result),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      } catch (e) {
        debugPrint('❌ Qdrant proxy error: $e');
        return http.Response(jsonEncode({'error': e.toString()}), 500);
      }
    }
    // Native: call Qdrant directly
    return http.post(
      Uri.parse('$endpoint$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
  }

  /// Maps a full Qdrant path to the proxy's short route, or null if not proxied.
  String? _toProxyPath(String path) {
    if (path.endsWith('/search')) return '/search';
    if (path.endsWith('/scroll')) return '/scroll';
    if (path.endsWith('/points') && !path.contains('/index')) return '/doc';
    return null;
  }

  Future<http.Response> _put(String path, Map<String, dynamic> body) =>
      http.put(
        Uri.parse('$endpoint$path'),
        headers: _headers,
        body: jsonEncode(body),
      );

  Future<http.Response> _delete(String path) =>
      http.delete(Uri.parse('$endpoint$path'), headers: _headers);
}
