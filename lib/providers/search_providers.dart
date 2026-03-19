import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domains/search/data/client/qdrant_client.dart';
import '../domains/search/data/repository/search_repository_impl.dart';
import '../domains/search/domain/repository/search_repository.dart';
import '../utils/env_loader.dart';
import '../core/functions/functions_client.dart';
import 'vertex_ai_provider.dart';

/// Qdrant configuration provider
/// Reads from --dart-define-from-file=env.json
final qdrantConfigProvider = Provider<Map<String, String>>((ref) {
  final config = EnvLoader.qdrant;

  return {
    'endpoint': config['endpoint'] as String? ?? 'YOUR_QDRANT_ENDPOINT',
    'apiKey':   config['apiKey']   as String? ?? 'YOUR_QDRANT_API_KEY',
    'collection': config['collection'] as String? ?? 'pubmed_articles',
  };
});

/// Qdrant client provider
/// On web, routes search through an Appwrite Functions proxy to avoid CORS.
final qdrantClientProvider = Provider<QdrantClient>((ref) {
  final config = ref.watch(qdrantConfigProvider);

  // Use Appwrite Functions proxy for web (Qdrant Cloud blocks browser requests)
  final functionsClient = kIsWeb ? ref.watch(functionsClientProvider) : null;

  return QdrantClient(
    endpoint:       config['endpoint']!,
    apiKey:         config['apiKey']!,
    collectionName: config['collection']!,
    functionsClient: functionsClient,
  );
});

/// Search repository provider with hybrid search support
final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  final client = ref.watch(qdrantClientProvider);

  // Try to get embeddings service, but don't fail if unavailable
  try {
    final embeddingsService = ref.watch(vertexAiProvider);
    return SearchRepositoryImpl(client, embeddingsService);
  } catch (e) {
    debugPrint('⚠️  Vertex AI not available, using keyword-only search: $e');
    return SearchRepositoryImpl(client);
  }
});
