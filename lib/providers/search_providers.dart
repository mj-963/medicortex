import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domains/search/data/client/elasticsearch_client.dart';
import '../domains/search/data/repository/search_repository_impl.dart';
import '../domains/search/domain/repository/search_repository.dart';
import '../utils/env_loader.dart';
import '../core/functions/functions_client.dart';
import 'vertex_ai_provider.dart';

/// Elasticsearch configuration provider
/// Reads from --dart-define-from-file=env.json
final elasticsearchConfigProvider = Provider<Map<String, String>>((ref) {
  final esConfig = EnvLoader.elasticsearch;

  return {
    'endpoint': esConfig['endpoint'] as String? ?? 'YOUR_ELASTICSEARCH_ENDPOINT',
    'apiKey': esConfig['apiKey'] as String? ?? 'YOUR_ELASTICSEARCH_API_KEY',
    'index': esConfig['index'] as String? ?? 'pubmed_articles',
  };
});

/// Elasticsearch client provider
final elasticsearchClientProvider = Provider<ElasticsearchClient>((ref) {
  final config = ref.watch(elasticsearchConfigProvider);

  // Use Appwrite Functions proxy for web to avoid CORS
  final functionsClient = kIsWeb ? ref.watch(functionsClientProvider) : null;

  return ElasticsearchClient(
    endpoint: config['endpoint']!,
    apiKey: config['apiKey']!,
    indexName: config['index']!,
    functionsClient: functionsClient,
  );
});

/// Search repository provider with hybrid search support
final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  final client = ref.watch(elasticsearchClientProvider);
  
  // Try to get embeddings service, but don't fail if unavailable
  try {
    final embeddingsService = ref.watch(vertexAiProvider);
    return SearchRepositoryImpl(client, embeddingsService);
  } catch (e) {
    debugPrint('⚠️  Vertex AI not available, using keyword-only search: $e');
    return SearchRepositoryImpl(client);
  }
});
