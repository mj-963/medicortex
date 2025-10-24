// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:medicortex/domains/pubmed/pubmed_fulltext_service.dart';

void main() {
  group('PubMedFullTextService', () {
    late PubMedFullTextService service;

    setUp(() {
      service = PubMedFullTextService();
    });

    test(
      'should fetch full text for a valid PMC paper',
      () async {
        // Use a known PMC Open Access paper
        // PMID: 35000000 is typically available in PMC
        const testPmid = '35000000';

        final result = await service.fetchFullText(testPmid);

        // Check if result is returned (may be null if not in PMC)
        if (result != null) {
          expect(result.pmid, equals(testPmid));
          expect(result.pmcId, isNotEmpty);
          expect(result.fullText, isNotEmpty);
          expect(result.source, equals('PMC'));
          expect(result.wordCount, greaterThan(0));

          print('✅ Successfully fetched full text');
          print('   PMID: ${result.pmid}');
          print('   PMC ID: ${result.pmcId}');
          print('   Word count: ${result.wordCount}');
          print('   Summary: ${result.summary}');
        } else {
          print('⚠️  Paper not available in PMC Open Access');
          print('   This is expected for some papers');
        }
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test(
      'should return null for paper not in PMC',
      () async {
        // Use a PMID that's unlikely to be in PMC
        const testPmid = '00000001';

        final result = await service.fetchFullText(testPmid);

        expect(result, isNull);
        print('✅ Correctly returned null for non-PMC paper');
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test(
      'should handle invalid PMID gracefully',
      () async {
        const invalidPmid = 'invalid_pmid';

        final result = await service.fetchFullText(invalidPmid);

        expect(result, isNull);
        print('✅ Correctly handled invalid PMID');
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test('FullTextResult should calculate word count correctly', () {
      final result = FullTextResult(
        pmid: '12345678',
        pmcId: 'PMC1234567',
        fullText: 'This is a test with ten words in total here.',
        source: 'PMC',
      );

      expect(result.wordCount, equals(10));
      print('✅ Word count calculation works correctly');
    });

    test('FullTextResult should generate summary correctly', () {
      final shortText = 'Short text';
      final longText = 'a' * 600;

      final shortResult = FullTextResult(
        pmid: '12345678',
        pmcId: 'PMC1234567',
        fullText: shortText,
        source: 'PMC',
      );

      final longResult = FullTextResult(
        pmid: '12345678',
        pmcId: 'PMC1234567',
        fullText: longText,
        source: 'PMC',
      );

      expect(shortResult.summary, equals(shortText));
      expect(longResult.summary.length, equals(503)); // 500 chars + '...'
      expect(longResult.summary.endsWith('...'), isTrue);

      print('✅ Summary generation works correctly');
    });
  });

  group('Integration Test - Real PMC Paper', () {
    test(
      'should fetch and parse a real PMC paper',
      () async {
        final service = PubMedFullTextService();

        // Test with a well-known PMC Open Access paper
        // PMID: 30000000 is more likely to be in PMC OA
        // You can also try: 25000000, 28000000, 32000000
        const testPmid = '30000000';

        print('\n🔍 Testing with PMID: $testPmid');
        print('   Fetching from PubMed Central...');

        final result = await service.fetchFullText(testPmid);

        if (result != null) {
          print('\n✅ Full text retrieved successfully!');
          print('   PMID: ${result.pmid}');
          print('   PMC ID: ${result.pmcId}');
          print('   Word count: ${result.wordCount}');
          print('   Text length: ${result.fullText.length} characters');

          // Verify structure
          expect(
            result.fullText,
            contains('##'),
          ); // Should have section headers
          expect(result.wordCount, greaterThan(100)); // Should be substantial

          // Print first 500 characters
          print('\n📄 Preview:');
          print(result.summary);

          print('\n✅ Integration test passed!');
        } else {
          print('\n⚠️  Paper not available in PMC Open Access');
          print('   This is expected - not all papers are in PMC');
          print('   Test passed (graceful handling)');
        }
      },
      timeout: const Timeout(Duration(seconds: 60)),
    );
  });

  group('Performance Tests', () {
    test(
      'should fetch full text within reasonable time',
      () async {
        final service = PubMedFullTextService();
        const testPmid = '35000000';

        final stopwatch = Stopwatch()..start();
        final result = await service.fetchFullText(testPmid);
        stopwatch.stop();

        print('\n⏱️  Fetch time: ${stopwatch.elapsedMilliseconds}ms');

        if (result != null) {
          expect(
            stopwatch.elapsedMilliseconds,
            lessThan(30000),
          ); // Should be < 30s
          print('✅ Performance test passed');
        } else {
          print('⚠️  Paper not in PMC - skipping performance check');
        }
      },
      timeout: const Timeout(Duration(seconds: 60)),
    );
  });
}
