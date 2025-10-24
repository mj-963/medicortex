/// Analytics data models for MediCortex
class AnalyticsData {
  final SearchAnalytics searchAnalytics;
  final UserEngagement userEngagement;
  final ContentMetrics contentMetrics;
  final SystemMetrics systemMetrics;

  AnalyticsData({
    required this.searchAnalytics,
    required this.userEngagement,
    required this.contentMetrics,
    required this.systemMetrics,
  });
}

/// Search analytics
class SearchAnalytics {
  final int totalSearches;
  final List<PopularQuery> topQueries;
  final List<PopularPaper> topPapers;
  final Map<String, int> searchesByDay;
  final double averageResultsPerSearch;

  SearchAnalytics({
    required this.totalSearches,
    required this.topQueries,
    required this.topPapers,
    required this.searchesByDay,
    required this.averageResultsPerSearch,
  });
}

class PopularQuery {
  final String query;
  final int count;
  final DateTime lastSearched;

  PopularQuery({
    required this.query,
    required this.count,
    required this.lastSearched,
  });
}

class PopularPaper {
  final String pmid;
  final String title;
  final int viewCount;
  final int citationCount;

  PopularPaper({
    required this.pmid,
    required this.title,
    required this.viewCount,
    required this.citationCount,
  });
}

/// User engagement metrics
class UserEngagement {
  final int totalConversations;
  final int totalMessages;
  final int totalAIQueries;
  final List<FeatureUsage> featureUsage;
  final Map<String, int> messagesByDay;
  final double averageMessagesPerConversation;

  UserEngagement({
    required this.totalConversations,
    required this.totalMessages,
    required this.totalAIQueries,
    required this.featureUsage,
    required this.messagesByDay,
    required this.averageMessagesPerConversation,
  });
}

class FeatureUsage {
  final String feature;
  final int usageCount;
  final String icon;

  FeatureUsage({
    required this.feature,
    required this.usageCount,
    required this.icon,
  });
}

/// Content metrics
class ContentMetrics {
  final int totalPapers;
  final int papersWithFullText;
  final List<TopicDistribution> topicDistribution;
  final Map<String, int> papersByYear;
  final double fullTextCoverage;

  ContentMetrics({
    required this.totalPapers,
    required this.papersWithFullText,
    required this.topicDistribution,
    required this.papersByYear,
    required this.fullTextCoverage,
  });
}

class TopicDistribution {
  final String topic;
  final int paperCount;
  final double percentage;

  TopicDistribution({
    required this.topic,
    required this.paperCount,
    required this.percentage,
  });
}

/// System metrics
class SystemMetrics {
  final double averageSearchTime;
  final double averageAIResponseTime;
  final int cacheHitRate;
  final String elasticsearchStatus;
  final String vertexAIStatus;

  SystemMetrics({
    required this.averageSearchTime,
    required this.averageAIResponseTime,
    required this.cacheHitRate,
    required this.elasticsearchStatus,
    required this.vertexAIStatus,
  });
}
