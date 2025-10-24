import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medicortex/providers/analytics_provider.dart';

class AnalyticsPage extends ConsumerWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final analyticsAsync = ref.watch(analyticsDataProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Analytics Dashboard',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: theme.cardColor,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: theme.dividerColor, height: 1),
        ),
      ),
      body: analyticsAsync.when(
        data:
            (analytics) => SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overview Cards
                  _buildOverviewSection(context, analytics),
                  const SizedBox(height: 32),

                  // Search Analytics
                  _buildSearchAnalytics(context, analytics),
                  const SizedBox(height: 32),

                  // User Engagement
                  _buildUserEngagement(context, analytics),
                  const SizedBox(height: 32),

                  // Content Metrics
                  _buildContentMetrics(context, analytics),
                  const SizedBox(height: 32),

                  // System Health
                  _buildSystemMetrics(context, analytics),
                ],
              ),
            ),
        loading:
            () => Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
            ),
        error: (error, stack) {
          return Center(
            child: Text(
              'Error loading analytics: $error',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverviewSection(BuildContext context, analytics) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context: context,
                icon: Icons.search,
                iconColor: theme.colorScheme.primary,
                title: 'Total Searches',
                value: analytics.searchAnalytics.totalSearches.toString(),
                subtitle:
                    '${analytics.searchAnalytics.topQueries.length} unique queries',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                context: context,
                icon: Icons.chat_bubble_outline,
                iconColor: Colors.green,
                title: 'Conversations',
                value: analytics.userEngagement.totalConversations.toString(),
                subtitle: '${analytics.userEngagement.totalMessages} messages',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                context: context,
                icon: Icons.article_outlined,
                iconColor: Colors.orange,
                title: 'Total Papers',
                value:
                    '${(analytics.contentMetrics.totalPapers / 1000).toStringAsFixed(0)}K',
                subtitle:
                    '${analytics.contentMetrics.fullTextCoverage.toStringAsFixed(0)}% with full text',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                context: context,
                icon: Icons.speed,
                iconColor: Colors.purple,
                title: 'Avg Search Time',
                value: '${analytics.systemMetrics.averageSearchTime}s',
                subtitle: 'Fast & efficient',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAnalytics(BuildContext context, analytics) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Search Analytics',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Top Queries',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...analytics.searchAnalytics.topQueries.take(5).map((query) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(query.query, style: theme.textTheme.bodyMedium),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${query.count} searches',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildUserEngagement(BuildContext context, analytics) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.people, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                'User Engagement',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  context,
                  'Total Messages',
                  analytics.userEngagement.totalMessages.toString(),
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  context,
                  'AI Queries',
                  analytics.userEngagement.totalAIQueries.toString(),
                  theme.colorScheme.primary,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  context,
                  'Avg Messages/Conv',
                  analytics.userEngagement.averageMessagesPerConversation
                      .toStringAsFixed(1),
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Feature Usage',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...analytics.userEngagement.featureUsage.map((feature) {
            final maxUsage = analytics.userEngagement.featureUsage
                .map((f) => f.usageCount)
                .reduce((a, b) => a > b ? a : b);
            // FIX: Prevent NaN by checking for zero or invalid values
            final percentage =
                (maxUsage > 0)
                    ? ((feature.usageCount / maxUsage) * 100).clamp(0.0, 100.0)
                    : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(feature.icon, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text(
                        feature.feature,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${feature.usageCount} uses',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.green,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildContentMetrics(BuildContext context, analytics) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.library_books, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                'Content Metrics',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Topic Distribution',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...analytics.contentMetrics.topicDistribution.map((topic) {
            // FIX: Prevent NaN by validating percentage
            final safePercentage =
                (topic.percentage.isFinite && topic.percentage >= 0)
                    ? topic.percentage.clamp(0.0, 100.0)
                    : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          topic.topic,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        '${topic.paperCount.toString()} papers (${safePercentage.toStringAsFixed(0)}%)',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: safePercentage / 100,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.orange,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSystemMetrics(BuildContext context, analytics) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.monitor_heart, color: Colors.purple),
              const SizedBox(width: 8),
              Text(
                'System Health',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildHealthCard(
                  context,
                  'Elasticsearch',
                  analytics.systemMetrics.elasticsearchStatus,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildHealthCard(
                  context,
                  'Vertex AI',
                  analytics.systemMetrics.vertexAIStatus,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  context,
                  'Avg Search Time',
                  '${analytics.systemMetrics.averageSearchTime}s',
                  theme.colorScheme.primary,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  context,
                  'Avg AI Response',
                  '${analytics.systemMetrics.averageAIResponseTime}s',
                  Colors.purple,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  context,
                  'Cache Hit Rate',
                  '${analytics.systemMetrics.cacheHitRate}%',
                  Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthCard(
    BuildContext context,
    String title,
    String status,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                status,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
