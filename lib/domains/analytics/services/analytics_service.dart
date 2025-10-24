import 'package:flutter/foundation.dart';
import 'package:medicortex/domains/analytics/models/analytics_data.dart';
import 'package:medicortex/domains/conversation/services/conversation_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for collecting and analyzing usage analytics
class AnalyticsService {
  final SharedPreferences prefs;

  AnalyticsService(this.prefs);

  /// Get comprehensive analytics data
  Future<AnalyticsData> getAnalytics() async {
    final searchAnalytics = await _getSearchAnalytics();
    final userEngagement = await _getUserEngagement();
    final contentMetrics = await _getContentMetrics();
    final systemMetrics = _getSystemMetrics();

    return AnalyticsData(
      searchAnalytics: searchAnalytics,
      userEngagement: userEngagement,
      contentMetrics: contentMetrics,
      systemMetrics: systemMetrics,
    );
  }

  /// Get search analytics from SharedPreferences
  Future<SearchAnalytics> _getSearchAnalytics() async {
    // Load search history from SharedPreferences (stored as query string format)
    List<Map<String, dynamic>> historyList = [];

    try {
      final historyStringList = prefs.getStringList('search_history');
      debugPrint(
        '📊 [Analytics] Raw search_history length: ${historyStringList?.length ?? 0}',
      );

      if (historyStringList != null && historyStringList.isNotEmpty) {
        debugPrint(
          '📊 [Analytics] First item sample: ${historyStringList.first}',
        );

        for (final queryString in historyStringList) {
          try {
            // Parse query string format: query=...&timestamp=...&resultCount=...
            final params = Uri.splitQueryString(
              queryString,
            ).map((key, value) => MapEntry(key, Uri.decodeComponent(value)));

            debugPrint('📊 [Analytics] Parsed params: $params');

            if (params.containsKey('query') &&
                params.containsKey('timestamp')) {
              historyList.add({
                'query': params['query'],
                'timestamp': params['timestamp'],
                'resultCount': int.tryParse(params['resultCount'] ?? '0') ?? 0,
                'conversationId':
                    params['conversationId'] != null
                        ? int.tryParse(params['conversationId']!)
                        : null,
              });
              debugPrint('📊 [Analytics] Added item: ${params['query']}');
            } else {
              debugPrint(
                '⚠️ [Analytics] Missing query or timestamp in params: $params',
              );
            }
          } catch (e) {
            debugPrint(
              '❌ [Analytics] Skipping invalid history item: $queryString - $e',
            );
          }
        }

        debugPrint(
          '📊 [Analytics] Final historyList length: ${historyList.length}',
        );
      } else {
        debugPrint('⚠️ [Analytics] search_history is null or empty');
      }
    } catch (e) {
      debugPrint('❌ [Analytics] Error loading search_history: $e');
    }

    // Count total searches
    final totalSearches = historyList.length;

    // Get top queries
    final queryMap = <String, int>{};
    final queryLastSearched = <String, DateTime>{};

    for (final item in historyList) {
      try {
        final query = item['query'] as String?;
        final timestampStr = item['timestamp'] as String?;

        if (query == null || timestampStr == null) continue;

        final timestamp = DateTime.parse(timestampStr);

        queryMap[query] = (queryMap[query] ?? 0) + 1;
        if (!queryLastSearched.containsKey(query) ||
            timestamp.isAfter(queryLastSearched[query]!)) {
          queryLastSearched[query] = timestamp;
        }
      } catch (e) {
        // Skip invalid items
        debugPrint('Skipping invalid query item: $e');
      }
    }

    final topQueries =
        queryMap.entries
            .map(
              (e) => PopularQuery(
                query: e.key,
                count: e.value,
                lastSearched: queryLastSearched[e.key]!,
              ),
            )
            .toList()
          ..sort((a, b) => b.count.compareTo(a.count));

    // Get searches by day
    final searchesByDay = <String, int>{};
    for (final item in historyList) {
      try {
        final timestampStr = item['timestamp'] as String?;
        if (timestampStr == null) continue;

        final timestamp = DateTime.parse(timestampStr);
        final day = timestamp.toIso8601String().split('T')[0];
        searchesByDay[day] = (searchesByDay[day] ?? 0) + 1;
      } catch (e) {
        // Skip invalid timestamp
        debugPrint('Skipping invalid timestamp in searchesByDay: $e');
      }
    }

    // Calculate average results per search
    double averageResults = 0.0;
    if (historyList.isNotEmpty) {
      final totalResults = historyList.fold<int>(
        0,
        (sum, item) => sum + (item['resultCount'] as int? ?? 0),
      );
      averageResults = totalResults / historyList.length;
    }

    final analytics = SearchAnalytics(
      totalSearches: totalSearches,
      topQueries: topQueries.take(10).toList(),
      topPapers: [], // TODO: Track paper views
      searchesByDay: searchesByDay,
      averageResultsPerSearch: averageResults,
    );

    debugPrint('📊 [Analytics] Search Analytics Summary:');
    debugPrint('   Total Searches: $totalSearches');
    debugPrint('   Top Queries: ${topQueries.length} unique queries');
    debugPrint('   Searches by Day: ${searchesByDay.length} days');

    return analytics;
  }

  /// Get user engagement metrics
  Future<UserEngagement> _getUserEngagement() async {
    // Get real conversation data from database
    final conversations = await ConversationDatabase.getAllConversations();
    final totalConversations = conversations.length;

    // Count total messages across all conversations
    int totalMessages = 0;
    int totalAIQueries = 0;
    final messagesByDay = <String, int>{};

    for (final conversation in conversations) {
      final messages = await ConversationDatabase.getMessages(conversation.id);
      totalMessages += messages.length;

      // Count AI queries (user messages)
      totalAIQueries += messages.where((m) => m.isUser).length;

      // Group messages by day
      for (final message in messages) {
        final day = message.timestamp.toIso8601String().split('T')[0];
        messagesByDay[day] = (messagesByDay[day] ?? 0) + 1;
      }
    }

    // Calculate average messages per conversation
    final avgMessages =
        totalConversations > 0 ? totalMessages / totalConversations : 0.0;

    // Get search history for feature usage estimation (stored as query string format)
    int totalSearches = 0;

    try {
      final historyStringList = prefs.getStringList('search_history');
      if (historyStringList != null) {
        totalSearches = historyStringList.length;
      }
    } catch (e) {
      debugPrint('Error loading search_history count for engagement: $e');
    }

    // Feature usage (estimated based on usage patterns)
    final featureUsage = [
      FeatureUsage(feature: 'Search', usageCount: totalSearches, icon: '🔍'),
      FeatureUsage(feature: 'AI Chat', usageCount: totalAIQueries, icon: '💬'),
      FeatureUsage(
        feature: 'Conversations',
        usageCount: totalConversations,
        icon: '📝',
      ),
      FeatureUsage(
        feature: 'Synthesize',
        usageCount: (totalAIQueries * 0.2).round(),
        icon: '📊',
      ),
      FeatureUsage(
        feature: 'Compare',
        usageCount: (totalAIQueries * 0.15).round(),
        icon: '⚖️',
      ),
    ];

    return UserEngagement(
      totalConversations: totalConversations,
      totalMessages: totalMessages,
      totalAIQueries: totalAIQueries,
      featureUsage: featureUsage,
      messagesByDay: messagesByDay,
      averageMessagesPerConversation: avgMessages,
    );
  }

  /// Get content metrics
  Future<ContentMetrics> _getContentMetrics() async {
    // Mock data - in production, query Elasticsearch
    final totalPapers = 50000; // From enhanced ingestion
    final papersWithFullText = 15000; // Estimated PMC coverage

    final topicDistribution = [
      TopicDistribution(
        topic: 'Chronic Diseases',
        paperCount: 8000,
        percentage: 16.0,
      ),
      TopicDistribution(topic: 'Cancer', paperCount: 6000, percentage: 12.0),
      TopicDistribution(
        topic: 'Mental Health',
        paperCount: 5000,
        percentage: 10.0,
      ),
      TopicDistribution(
        topic: 'Infectious Diseases',
        paperCount: 4500,
        percentage: 9.0,
      ),
      TopicDistribution(
        topic: 'Neurological',
        paperCount: 4000,
        percentage: 8.0,
      ),
      TopicDistribution(topic: 'Autoimmune', paperCount: 3500, percentage: 7.0),
      TopicDistribution(topic: 'Other', paperCount: 19000, percentage: 38.0),
    ];

    final papersByYear = {
      '2024': 8000,
      '2023': 12000,
      '2022': 10000,
      '2021': 8000,
      '2020': 7000,
      'Older': 5000,
    };

    final fullTextCoverage = (papersWithFullText / totalPapers) * 100;

    return ContentMetrics(
      totalPapers: totalPapers,
      papersWithFullText: papersWithFullText,
      topicDistribution: topicDistribution,
      papersByYear: papersByYear,
      fullTextCoverage: fullTextCoverage,
    );
  }

  /// Get system metrics
  SystemMetrics _getSystemMetrics() {
    return SystemMetrics(
      averageSearchTime: 1.2, // seconds
      averageAIResponseTime: 3.5, // seconds
      cacheHitRate: 85, // percentage
      elasticsearchStatus: 'Healthy',
      vertexAIStatus: 'Operational',
    );
  }
}
