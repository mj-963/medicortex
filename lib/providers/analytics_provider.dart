import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medicortex/domains/analytics/models/analytics_data.dart';
import 'package:medicortex/domains/analytics/services/analytics_service.dart';
import 'package:medicortex/providers/settings_providers.dart';

/// Provider for analytics service
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AnalyticsService(prefs);
});

/// Provider for analytics data
final analyticsDataProvider = FutureProvider<AnalyticsData>((ref) async {
  final service = ref.watch(analyticsServiceProvider);
  return await service.getAnalytics();
});
