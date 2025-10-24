import 'package:flutter/foundation.dart';

import '../../domain/entities/search_query.dart';
import '../../domain/entities/search_result.dart';
import '../../domain/repository/search_repository.dart';
import '../client/elasticsearch_client.dart';
import '../../../ai/infrastructure/vertex_ai_embeddings_service.dart';

/// Implementation of SearchRepository using Elasticsearch
class SearchRepositoryImpl implements SearchRepository {
  final ElasticsearchClient _client;
  final VertexAiEmbeddingsService? _embeddingsService;

  SearchRepositoryImpl(this._client, [this._embeddingsService]);

  @override
  Future<SearchResults> search(SearchQuery query) async {
    final filters = <String, dynamic>{};

    // Add article type filter if specified
    if (query.articleTypes != null && query.articleTypes!.isNotEmpty) {
      filters['article_type'] = query.articleTypes!.first;
    }

    // Add date range filter if provided
    if (query.fromDate != null || query.toDate != null) {
      final dateRange = <String, String>{};
      if (query.fromDate != null) {
        dateRange['gte'] = query.fromDate!.toIso8601String();
      }
      if (query.toDate != null) {
        dateRange['lte'] = query.toDate!.toIso8601String();
      }
      filters['publication_date'] = dateRange;
    }

    // Merge with any additional filters
    if (query.filters != null) {
      filters.addAll(query.filters!);
    }

    // Generate query embedding for hybrid search if service is available
    List<double>? queryEmbedding;
    if (_embeddingsService != null) {
      try {
        queryEmbedding = await _embeddingsService?.generateQueryEmbedding(
          query.query,
        );
        debugPrint('✅ Using hybrid search (vector + keyword)');
      } catch (e) {
        debugPrint('⚠️  Embeddings failed, falling back to keyword search: $e');
      }
    }

    return _client.hybridSearch(
      query: query.query,
      queryEmbedding: queryEmbedding,
      size: query.maxResults,
      filters: filters.isNotEmpty ? filters : null,
    );
  }

  @override
  Future<void> initialize() async {
    if (!await _client.indexExists()) {
      debugPrint('🔨 Creating Elasticsearch index...');
      await _client.createIndex();
    } else {
      debugPrint('✅ Elasticsearch index already exists');
      final stats = await _client.getIndexStats();
      debugPrint('📊 Index has ${stats['document_count']} documents');
    }
  }

  @override
  Future<bool> isReady() async {
    try {
      final connected = await _client.testConnection();
      if (!connected) return false;

      final exists = await _client.indexExists();
      return exists;
    } catch (e) {
      debugPrint('❌ Search service not ready: $e');
      return false;
    }
  }
}
