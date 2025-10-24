// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicortex/domains/ai/application/rag_service.dart';
import 'package:medicortex/domains/ai/data/ai_repository_impl.dart';
import 'package:medicortex/domains/search/data/client/elasticsearch_client.dart';
import 'package:medicortex/domains/ai/infrastructure/vertex_ai_embeddings_service.dart';

void main() {
  late RagService ragService;
  late Map<String, dynamic> config;

  setUpAll(() async {
    final envFile = File('env.json');
    if (!envFile.existsSync()) {
      throw Exception('env.json not found');
    }

    config = jsonDecode(envFile.readAsStringSync());

    // Initialize AI Repository
    final geminiApiKey = config['gemini_api_key'] ?? config['google_api_key'];
    if (geminiApiKey == null) {
      throw Exception('Gemini API key not found in env.json');
    }

    final aiRepository = AiRepositoryImpl(geminiApiKey);

    // Initialize Elasticsearch
    final elasticConfig = config['elasticsearch'];
    final elasticClient = ElasticsearchClient(
      endpoint: elasticConfig['endpoint'],
      apiKey: elasticConfig['apiKey'],
      indexName: elasticConfig['index'] ?? 'pubmed_articles',
    );

    // Initialize Vertex AI
    final vertexConfig = config['vertex_ai'];
    final embeddingsService = VertexAiEmbeddingsService(
      projectId: vertexConfig['project_id'],
      location: vertexConfig['location'] ?? 'us-central1',
      serviceAccount: config['service_account'],
    );

    // Create RAG service
    ragService = RagService(
      aiRepository: aiRepository,
      elasticClient: elasticClient,
      embeddingsService: embeddingsService,
    );

    print('RAG Service initialized successfully');
  });

  group('RAG Service Tests', () {
    test(
      'should answer question with context and citations',
      () async {
        final question = 'What are the main treatments for type 2 diabetes?';

        print('Testing RAG pipeline...');
        print('Question: $question');

        final response = await ragService.answerWithContext(
          question: question,
          maxResults: 5,
        );

        expect(response, isNotNull);
        expect(response.answer, isNotEmpty);
        expect(response.sources, isNotEmpty);
        expect(response.confidence, greaterThan(0.0));
        if (kDebugMode) {
          print('Answer length: ${response.answer.length} characters');
          print('Sources: ${response.sources.length}');
          print('Confidence: ${response.confidence.toStringAsFixed(2)}');
          print('Search time: ${response.searchTime?.inMilliseconds}ms');
          print('');
          print('Answer preview:');
          print(
            response.answer.substring(
              0,
              response.answer.length > 200 ? 200 : response.answer.length,
            ),
          );
          print('...');
          print('');
          print('Sources:');
        }
        for (int i = 0; i < response.sources.take(3).length; i++) {
          final source = response.sources[i];
          print('  [${i + 1}] ${source.title}');
          print(
            '      PMID: ${source.id}, Score: ${source.score.toStringAsFixed(2)}',
          );
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'should synthesize findings from multiple papers',
      () async {
        print('Testing paper synthesis...');

        // First, search for papers
        final searchResults = await ragService.elasticClient.hybridSearch(
          query: 'diabetes treatment',
          size: 5,
        );

        expect(searchResults.results, isNotEmpty);

        final synthesis = await ragService.synthesizePapers(
          papers: searchResults.results,
          topic: 'diabetes treatment',
        );

        expect(synthesis, isNotEmpty);
        print('Synthesis length: ${synthesis.length} characters');
        print('');
        print('Synthesis preview:');
        print(
          synthesis.substring(
            0,
            synthesis.length > 300 ? 300 : synthesis.length,
          ),
        );
        print('...');
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'should suggest follow-up questions',
      () async {
        print('Testing follow-up question generation...');

        final searchResults = await ragService.elasticClient.hybridSearch(
          query: 'covid vaccine efficacy',
          size: 3,
        );

        expect(searchResults.results, isNotEmpty);

        final followUps = await ragService.suggestFollowUpQuestions(
          originalQuery: 'covid vaccine efficacy',
          papers: searchResults.results,
        );

        expect(followUps, isNotEmpty);
        expect(followUps.length, lessThanOrEqualTo(5));

        print('Generated ${followUps.length} follow-up questions:');
        for (int i = 0; i < followUps.length; i++) {
          print('  ${i + 1}. ${followUps[i]}');
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'should compare multiple studies',
      () async {
        print('Testing study comparison...');

        final searchResults = await ragService.elasticClient.hybridSearch(
          query: 'hypertension treatment',
          size: 3,
        );

        if (searchResults.results.length < 2) {
          print('Not enough papers for comparison');
          return;
        }

        final comparison = await ragService.compareStudies(
          papers: searchResults.results.take(2).toList(),
          comparisonAspect: 'treatment efficacy',
        );

        expect(comparison, isNotEmpty);
        print('Comparison length: ${comparison.length} characters');
        print('');
        print('Comparison preview:');
        print(
          comparison.substring(
            0,
            comparison.length > 300 ? 300 : comparison.length,
          ),
        );
        print('...');
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test('should extract key insights', () async {
      print('Testing key insights extraction...');

      final searchResults = await ragService.elasticClient.hybridSearch(
        query: 'mental health treatment',
        size: 5,
      );

      expect(searchResults.results, isNotEmpty);

      final insights = await ragService.extractKeyInsights(
        searchResults.results,
      );

      expect(insights, isNotEmpty);
      print('Extracted ${insights.length} key insights:');
      for (int i = 0; i < insights.take(5).length; i++) {
        print('  ${i + 1}. ${insights[i]}');
      }
    }, timeout: const Timeout(Duration(minutes: 2)));

    test(
      'should handle query with no results gracefully',
      () async {
        final question = 'xyzabc123nonsensequery456';

        print('Testing no results handling...');

        final response = await ragService.answerWithContext(
          question: question,
          maxResults: 5,
        );

        expect(response, isNotNull);
        expect(response.answer, contains('couldn\'t find'));
        expect(response.sources, isEmpty);
        expect(response.confidence, equals(0.0));

        print('No results response: ${response.answer}');
      },
      timeout: const Timeout(Duration(minutes: 1)),
    );

    test(
      'should calculate confidence scores correctly',
      () async {
        final question = 'diabetes';

        print('Testing confidence scoring...');

        final response = await ragService.answerWithContext(
          question: question,
          maxResults: 5,
        );

        expect(response.confidence, greaterThanOrEqualTo(0.0));
        expect(response.confidence, lessThanOrEqualTo(1.0));

        print('Confidence score: ${response.confidence.toStringAsFixed(3)}');
        print('Based on ${response.sources.length} sources');

        if (response.sources.isNotEmpty) {
          final avgScore =
              response.sources
                  .take(3)
                  .map((s) => s.score)
                  .reduce((a, b) => a + b) /
              response.sources.take(3).length;
          print(
            'Average top-3 relevance score: ${avgScore.toStringAsFixed(2)}',
          );
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });

  tearDownAll(() {
    print('All RAG service tests completed!');
  });
}
