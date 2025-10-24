/// Represents a single search result from Elasticsearch
class SearchResult {
  final String id;
  final String title;
  final String abstract;
  final double score;
  final DateTime? publicationDate;
  final String sourceUrl;
  final List<String> authors;
  final Map<String, dynamic> metadata;

  const SearchResult({
    required this.id,
    required this.title,
    required this.abstract,
    required this.score,
    this.publicationDate,
    required this.sourceUrl,
    this.authors = const [],
    this.metadata = const {},
  });

  /// Format as citation for display
  String get citation {
    final year = publicationDate?.year.toString() ?? 'N/A';
    return '[$id] $title (PubMed $year)';
  }

  /// Short version of abstract for preview
  String get shortAbstract {
    if (abstract.isEmpty) return '';
    if (abstract.length <= 200) return abstract;
    return '${abstract.substring(0, 200)}...';
  }

  /// URL to PubMed article
  String get pubmedUrl => 'https://pubmed.ncbi.nlm.nih.gov/$id/';

  @override
  String toString() => 'SearchResult(id: $id, title: $title, score: $score)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchResult &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Collection of search results with metadata
class SearchResults {
  final List<SearchResult> results;
  final int totalHits;
  final Duration searchTime;
  final String query;

  const SearchResults({
    required this.results,
    required this.totalHits,
    required this.searchTime,
    required this.query,
  });

  bool get isEmpty => results.isEmpty;
  bool get isNotEmpty => results.isNotEmpty;
  int get count => results.length;

  /// Format for display
  String get summary =>
      'Found $totalHits results in ${searchTime.inMilliseconds}ms (showing $count)';

  @override
  String toString() =>
      'SearchResults(query: "$query", totalHits: $totalHits, count: $count)';
}
