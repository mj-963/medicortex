import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicortex/domains/search/data/client/elasticsearch_client.dart';
import 'package:medicortex/domains/ai/infrastructure/vertex_ai_embeddings_service.dart';

void main() {
  late ElasticsearchClient elasticClient;
  late VertexAiEmbeddingsService embeddingsService;
  late Map<String, dynamic> config;

  setUpAll(() async {
    final envFile = File('env.json');
    if (!envFile.existsSync()) {
      throw Exception('env.json not found');
    }

    config = jsonDecode(envFile.readAsStringSync());

    final elasticConfig = config['elasticsearch'];
    elasticClient = ElasticsearchClient(
      endpoint: elasticConfig['endpoint'],
      apiKey: elasticConfig['apiKey'],
      indexName: elasticConfig['index'] ?? 'pubmed_articles',
    );

    final vertexConfig = config['vertex_ai'];
    embeddingsService = VertexAiEmbeddingsService(
      projectId: vertexConfig['project_id'],
      location: vertexConfig['location'] ?? 'us-central1',
      serviceAccount: config['service_account'],
    );

    if (kDebugMode) {
      print('Testing Elasticsearch connection...');
    }
    final connected = await elasticClient.testConnection();
    if (!connected) {
      throw Exception('Failed to connect to Elasticsearch');
    }
    if (kDebugMode) {
      print('Connected to Elasticsearch');
    }
  });

  group('Hybrid Search Tests', () {
    test('should perform keyword-only search', () async {
      final query = 'diabetes treatment';

      if (kDebugMode) {
        print('Testing keyword-only search...');
      }
      final results = await elasticClient.hybridSearch(query: query, size: 5);

      expect(results, isNotNull);
      expect(results.results, isNotEmpty);

      if (kDebugMode) {
        print('Found ${results.totalHits} total hits');
      }
      if (kDebugMode) {
        print('Showing ${results.results.length} results');
        print('Search time: ${results.searchTime.inMilliseconds}ms');
      }

      if (results.results.isNotEmpty) {
        final topResult = results.results.first;
        if (kDebugMode) {
          print('Top result: ${topResult.title}');
          print('Score: ${topResult.score}');
        }
      }
    });

    test('should perform hybrid search with embeddings', () async {
      final query = 'type 2 diabetes treatment guidelines';

      if (kDebugMode) {
        print('Testing hybrid search with embeddings...');
      }

      final queryEmbedding = await embeddingsService.generateQueryEmbedding(
        query,
      );
      if (kDebugMode) {
        print('Generated query embedding: ${queryEmbedding.length}-dim');
      }

      final results = await elasticClient.hybridSearch(
        query: query,
        queryEmbedding: queryEmbedding,
        size: 10,
      );

      expect(results, isNotNull);
      expect(results.results, isNotEmpty);

      if (kDebugMode) {
        print('Hybrid search found ${results.totalHits} total hits');
        print('Showing ${results.results.length} results');
        print('Search time: ${results.searchTime.inMilliseconds}ms');
      }

      for (int i = 0; i < results.results.take(3).length; i++) {
        final result = results.results[i];
        final titlePreview =
            result.title.length > 60
                ? result.title.substring(0, 60)
                : result.title;
        if (kDebugMode) {
          print('Result ${i + 1}: $titlePreview...');
          print('  Score: ${result.score.toStringAsFixed(2)}');
        }
      }
    });

    test('should apply year filter', () async {
      final query = 'covid vaccine';

      if (kDebugMode) {
        print('Testing search with year filter...');
      }

      final results = await elasticClient.hybridSearch(
        query: query,
        size: 5,
        filters: {
          'publication_date': {'gte': '2023-01-01'},
        },
      );

      expect(results, isNotNull);
      if (kDebugMode) {
        print('Found ${results.totalHits} results from 2023+');
      }

      for (final result in results.results) {
        if (result.publicationDate != null) {
          expect(result.publicationDate!.year, greaterThanOrEqualTo(2023));
          final titlePreview =
              result.title.length > 50
                  ? result.title.substring(0, 50)
                  : result.title;
          if (kDebugMode) {
            print('  ${result.publicationDate!.year}: $titlePreview...');
          }
        }
      }
    });

    test('should compare keyword vs hybrid search relevance', () async {
      final query = 'heart attack prevention';

      if (kDebugMode) {
        print('Comparing keyword vs hybrid search...');
      }

      final keywordResults = await elasticClient.hybridSearch(
        query: query,
        size: 5,
      );

      final queryEmbedding = await embeddingsService.generateQueryEmbedding(
        query,
      );
      final hybridResults = await elasticClient.hybridSearch(
        query: query,
        queryEmbedding: queryEmbedding,
        size: 5,
      );

      if (kDebugMode) {
        print('Keyword search: ${keywordResults.results.length} results');
        print('Hybrid search: ${hybridResults.results.length} results');
      }

      if (keywordResults.results.isNotEmpty &&
          hybridResults.results.isNotEmpty) {
        final keywordTitle =
            keywordResults.results.first.title.length > 50
                ? keywordResults.results.first.title.substring(0, 50)
                : keywordResults.results.first.title;
        final hybridTitle =
            hybridResults.results.first.title.length > 50
                ? hybridResults.results.first.title.substring(0, 50)
                : hybridResults.results.first.title;
        if (kDebugMode) {
          print('Top keyword result: $keywordTitle...');
          print('Top hybrid result: $hybridTitle...');
        }
      }
    });

    test('should handle semantic queries', () async {
      final query = 'myocardial infarction';

      if (kDebugMode) {
        print('Testing semantic search...');
      }

      final queryEmbedding = await embeddingsService.generateQueryEmbedding(
        query,
      );
      final results = await elasticClient.hybridSearch(
        query: query,
        queryEmbedding: queryEmbedding,
        size: 5,
      );

      expect(results, isNotNull);
      if (kDebugMode) {
        print('Found ${results.totalHits} results for semantic query');
      }

      final titlesLower =
          results.results.map((r) => r.title.toLowerCase()).toList();

      final hasHeartAttack = titlesLower.any((t) => t.contains('heart attack'));
      final hasMyocardial = titlesLower.any((t) => t.contains('myocardial'));

      if (kDebugMode) {
        print('Results contain "heart attack": $hasHeartAttack');
        print('Results contain "myocardial": $hasMyocardial');
      }

      expect(
        hasHeartAttack || hasMyocardial,
        isTrue,
        reason: 'Should find semantically related terms',
      );
    });
  });

  tearDownAll(() {
    embeddingsService.dispose();
    if (kDebugMode) {
      print('All hybrid search tests completed!');
    }
  });
}
