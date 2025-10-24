import '../entities/search_query.dart';
import '../entities/search_result.dart';

/// Repository interface for medical literature search
abstract class SearchRepository {
  /// Perform a search with the given query
  Future<SearchResults> search(SearchQuery query);

  /// Initialize the search infrastructure (create index, etc.)
  Future<void> initialize();

  /// Check if the search service is ready
  Future<bool> isReady();
}
