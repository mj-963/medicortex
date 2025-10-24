/// Search query parameters for medical literature search
class SearchQuery {
  final String query;
  final int maxResults;
  final DateTime? fromDate;
  final DateTime? toDate;
  final List<String>? articleTypes;
  final Map<String, dynamic>? filters;

  const SearchQuery({
    required this.query,
    this.maxResults = 10,
    this.fromDate,
    this.toDate,
    this.articleTypes,
    this.filters,
  });

  /// Create a copy with modified fields
  SearchQuery copyWith({
    String? query,
    int? maxResults,
    DateTime? fromDate,
    DateTime? toDate,
    List<String>? articleTypes,
    Map<String, dynamic>? filters,
  }) {
    return SearchQuery(
      query: query ?? this.query,
      maxResults: maxResults ?? this.maxResults,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      articleTypes: articleTypes ?? this.articleTypes,
      filters: filters ?? this.filters,
    );
  }

  @override
  String toString() => 'SearchQuery(query: "$query", maxResults: $maxResults)';
}
