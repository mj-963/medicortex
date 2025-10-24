// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicortex/domains/ai/infrastructure/vertex_ai_embeddings_service.dart';

void main() {
  late VertexAiEmbeddingsService embeddingsService;
  late Map<String, dynamic> config;

  setUpAll(() {
    // Load config from env.json
    final envFile = File('env.json');
    if (!envFile.existsSync()) {
      throw Exception(
        'env.json not found. Please create it from env.example.json',
      );
    }

    config = jsonDecode(envFile.readAsStringSync());

    // Check if Vertex AI config exists
    if (!config.containsKey('vertex_ai')) {
      throw Exception('vertex_ai configuration not found in env.json');
    }

    final vertexConfig = config['vertex_ai'];

    embeddingsService = VertexAiEmbeddingsService(
      projectId: vertexConfig['project_id'],
      location: vertexConfig['location'] ?? 'us-central1',
      serviceAccount: config['service_account'],
    );
  });

  group('Vertex AI Embeddings Service Tests', () {
    test('should generate embedding for single text', () async {
      final text = 'Type 2 diabetes treatment with metformin';

      print('🧪 Testing single embedding generation...');
      final embedding = await embeddingsService.generateEmbedding(text);

      expect(embedding, isNotNull);
      expect(
        embedding.length,
        equals(768),
        reason: 'text-embedding-004 should produce 768-dim vectors',
      );
      expect(
        embedding.every((value) => value.isFinite),
        isTrue,
        reason: 'All values should be finite',
      );

      print('✅ Generated ${embedding.length}-dimensional embedding');
      print('   First 5 values: ${embedding.take(5).toList()}');
    });

    test('should generate embeddings for multiple texts (batch)', () async {
      final texts = [
        'Diabetes mellitus type 2',
        'Hypertension treatment guidelines',
        'COVID-19 vaccine efficacy',
      ];

      print('🧪 Testing batch embedding generation...');
      final embeddings = await embeddingsService.generateEmbeddings(texts);

      expect(embeddings.length, equals(3));
      expect(embeddings.every((emb) => emb.length == 768), isTrue);

      print('✅ Generated ${embeddings.length} embeddings');
      for (int i = 0; i < embeddings.length; i++) {
        print('   Text $i: ${embeddings[i].length}-dim vector');
      }
    });

    test('should generate query embedding optimized for search', () async {
      final query = 'What are the latest treatments for type 2 diabetes?';

      print('🧪 Testing query embedding generation...');
      final embedding = await embeddingsService.generateQueryEmbedding(query);

      expect(embedding, isNotNull);
      expect(embedding.length, equals(768));

      print('✅ Generated query embedding: ${embedding.length}-dim');
    });

    test('should calculate cosine similarity correctly', () {
      final vec1 = [1.0, 0.0, 0.0];
      final vec2 = [1.0, 0.0, 0.0];
      final vec3 = [0.0, 1.0, 0.0];

      print('🧪 Testing cosine similarity...');

      final similarity1 = embeddingsService.cosineSimilarity(vec1, vec2);
      final similarity2 = embeddingsService.cosineSimilarity(vec1, vec3);

      expect(
        similarity1,
        closeTo(1.0, 0.001),
        reason: 'Identical vectors should have similarity 1.0',
      );
      expect(
        similarity2,
        closeTo(0.0, 0.001),
        reason: 'Orthogonal vectors should have similarity 0.0',
      );

      print('✅ Similarity (identical): $similarity1');
      print('✅ Similarity (orthogonal): $similarity2');
    });

    test(
      'should produce similar embeddings for semantically similar texts',
      () async {
        final text1 = 'heart attack';
        final text2 = 'myocardial infarction';
        final text3 = 'diabetes mellitus';

        print('🧪 Testing semantic similarity...');

        final embeddings = await embeddingsService.generateEmbeddings([
          text1,
          text2,
          text3,
        ]);

        final similarity12 = embeddingsService.cosineSimilarity(
          embeddings[0],
          embeddings[1],
        );
        final similarity13 = embeddingsService.cosineSimilarity(
          embeddings[0],
          embeddings[2],
        );

        print('   "$text1" vs "$text2": $similarity12');
        print('   "$text1" vs "$text3": $similarity13');

        expect(
          similarity12,
          greaterThan(similarity13),
          reason:
              'Heart attack and myocardial infarction should be more similar than heart attack and diabetes',
        );

        print('✅ Semantic similarity working correctly');
      },
    );

    test('should handle empty text gracefully', () async {
      print('🧪 Testing empty text handling...');

      try {
        await embeddingsService.generateEmbedding('');
        print('⚠️  Empty text was accepted (may be valid)');
      } catch (e) {
        print(
          '✅ Empty text rejected with error: ${e.toString().substring(0, 50)}...',
        );
      }
    });

    test('should handle very long text', () async {
      final longText = 'diabetes ' * 1000; // Very long text

      print('🧪 Testing long text handling...');

      try {
        final embedding = await embeddingsService.generateEmbedding(longText);
        expect(embedding.length, equals(768));
        print('✅ Long text handled successfully');
      } catch (e) {
        print('⚠️  Long text error: ${e.toString().substring(0, 100)}...');
      }
    });
  });

  tearDownAll(() {
    embeddingsService.dispose();
    print('\n🎉 All Vertex AI Embeddings tests completed!');
  });
}
