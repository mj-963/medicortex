import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/settings_providers.dart';

class SearchHistoryItem {
  final String query;
  final DateTime timestamp;
  final int resultCount;
  final int? conversationId; // Link to conversation session (Isar ID)

  SearchHistoryItem({
    required this.query,
    required this.timestamp,
    required this.resultCount,
    this.conversationId,
  });

  Map<String, dynamic> toJson() => {
        'query': query,
        'timestamp': timestamp.toIso8601String(),
        'resultCount': resultCount,
        'conversationId': conversationId,
      };

  factory SearchHistoryItem.fromJson(Map<String, dynamic> json) {
    return SearchHistoryItem(
      query: json['query'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      resultCount: json['resultCount'] as int,
      conversationId: json['conversationId'] as int?,
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    if (difference.inDays < 30) return '${(difference.inDays / 7).floor()}w ago';
    return '${(difference.inDays / 30).floor()}mo ago';
  }
}

class SearchHistoryNotifier extends StateNotifier<List<SearchHistoryItem>> {
  final SharedPreferences _prefs;
  static const String _key = 'search_history';
  static const int _maxItems = 50;

  SearchHistoryNotifier(this._prefs) : super([]) {
    _loadHistory();
  }

  void _loadHistory() {
    try {
      final jsonList = _prefs.getStringList(_key) ?? [];
      final items = jsonList
          .map((jsonStr) {
            try {
              final json = Map<String, dynamic>.from(
                Uri.splitQueryString(jsonStr).map(
                  (key, value) => MapEntry(key, Uri.decodeComponent(value)),
                ),
              );
              // Parse manually since we stored as query string
              return SearchHistoryItem(
                query: json['query'] ?? '',
                timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
                resultCount: int.parse(json['resultCount'] ?? '0'),
                conversationId: json['conversationId'] != null && json['conversationId']!.isNotEmpty
                    ? int.tryParse(json['conversationId']!)
                    : null,
              );
            } catch (e) {
              return null;
            }
          })
          .whereType<SearchHistoryItem>()
          .toList();

      state = items;
      debugPrint('📜 Loaded ${items.length} search history items from storage');
      for (final item in items.take(3)) {
        debugPrint('   - "${item.query}" (conversationId: ${item.conversationId})');
      }
    } catch (e) {
      debugPrint('⚠️ Error loading search history: $e');
      state = [];
    }
  }

  Future<void> addSearch(String query, int resultCount, {int? conversationId}) async {
    // Only remove if it's the SAME conversation being updated
    // Allow duplicate queries with different conversationIds
    final filtered = conversationId != null
        ? state.where((item) => item.conversationId != conversationId).toList()
        : state; // If no conversationId, keep all (shouldn't happen in practice)

    // Add new item at the beginning
    final newItem = SearchHistoryItem(
      query: query,
      timestamp: DateTime.now(),
      resultCount: resultCount,
      conversationId: conversationId,
    );

    debugPrint('💾 Saving search history: "$query" with conversationId: $conversationId');

    final updated = [newItem, ...filtered];

    // Keep only the last N items
    final trimmed = updated.take(_maxItems).toList();

    state = trimmed;
    await _saveHistory();
  }

  Future<void> removeSearch(int conversationId) async {
    state = state.where((item) => item.conversationId != conversationId).toList();
    await _saveHistory();
    debugPrint('🗑️ Removed search history for conversationId: $conversationId');
  }

  Future<void> clearHistory() async {
    state = [];
    await _prefs.remove(_key);
  }

  Future<void> _saveHistory() async {
    try {
      final jsonList = state.map((item) {
        // Store as simple query string format
        final conversationIdStr = item.conversationId != null ? '&conversationId=${item.conversationId}' : '';
        return 'query=${Uri.encodeComponent(item.query)}&'
            'timestamp=${Uri.encodeComponent(item.timestamp.toIso8601String())}&'
            'resultCount=${item.resultCount}$conversationIdStr';
      }).toList();

      await _prefs.setStringList(_key, jsonList);
    } catch (e) {
      // Ignore save errors
    }
  }
}

final searchHistoryProvider =
    StateNotifierProvider<SearchHistoryNotifier, List<SearchHistoryItem>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SearchHistoryNotifier(prefs);
});
