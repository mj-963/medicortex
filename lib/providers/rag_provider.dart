import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domains/ai/application/rag_service.dart';
import 'ai_providers.dart';
import 'search_providers.dart';
import 'vertex_ai_provider.dart';

/// Provider for RAG Service
final ragServiceProvider = Provider<RagService?>((ref) {
  final aiRepository = ref.watch(aiRepositoryProvider);

  // RAG service requires AI repository
  if (aiRepository == null) {
    return null;
  }

  final qdrantClient = ref.watch(qdrantClientProvider);
  final embeddingsService = ref.watch(vertexAiProvider);

  return RagService(
    aiRepository: aiRepository,
    qdrantClient: qdrantClient,
    embeddingsService: embeddingsService,
  );
});
