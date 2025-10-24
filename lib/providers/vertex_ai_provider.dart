import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domains/ai/infrastructure/vertex_ai_embeddings_service.dart';
import '../utils/env_loader.dart';

/// Provider for Vertex AI Embeddings Service
/// Reads from --dart-define-from-file=env.json
final vertexAiProvider = Provider<VertexAiEmbeddingsService>((ref) {
  final vertexConfig = EnvLoader.vertexAi;
  final serviceAccount = EnvLoader.serviceAccount;

  if (vertexConfig.isEmpty) {
    throw Exception('vertex_ai configuration not found in environment');
  }

  return VertexAiEmbeddingsService(
    projectId: vertexConfig['project_id'] as String,
    location: vertexConfig['location'] as String? ?? 'us-central1',
    serviceAccount: serviceAccount.isNotEmpty ? serviceAccount : null,
  );
});
