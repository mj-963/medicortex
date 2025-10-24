import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domains/search/domain/entities/search_result.dart';

/// Workspace state - Hero mode vs Research mode
enum WorkspaceMode { hero, research }

class WorkspaceState {
  final WorkspaceMode mode;
  final List<SearchResult> searchResults;
  final bool isSearching;
  final String? currentQuery;
  final SearchResult? selectedArticle; // For citation highlighting
  final String? webViewUrl;
  final bool isWebViewMinimized;

  const WorkspaceState({
    this.mode = WorkspaceMode.hero,
    this.searchResults = const [],
    this.isSearching = false,
    this.currentQuery,
    this.selectedArticle,
    this.webViewUrl,
    this.isWebViewMinimized = false,
  });

  WorkspaceState copyWith({
    WorkspaceMode? mode,
    List<SearchResult>? searchResults,
    bool? isSearching,
    String? currentQuery,
    SearchResult? selectedArticle,
    String? webViewUrl,
    bool? isWebViewMinimized,
    bool clearSelectedArticle = false,
    bool clearWebView = false,
  }) {
    return WorkspaceState(
      mode: mode ?? this.mode,
      searchResults: searchResults ?? this.searchResults,
      isSearching: isSearching ?? this.isSearching,
      currentQuery: currentQuery ?? this.currentQuery,
      selectedArticle: clearSelectedArticle ? null : (selectedArticle ?? this.selectedArticle),
      webViewUrl: clearWebView ? null : (webViewUrl ?? this.webViewUrl),
      isWebViewMinimized: isWebViewMinimized ?? this.isWebViewMinimized,
    );
  }
}

class WorkspaceNotifier extends StateNotifier<WorkspaceState> {
  WorkspaceNotifier() : super(const WorkspaceState());

  void switchToResearchMode() {
    state = state.copyWith(mode: WorkspaceMode.research);
  }

  void switchToHeroMode() {
    state = state.copyWith(
      mode: WorkspaceMode.hero,
      searchResults: [],
      currentQuery: null,
      clearSelectedArticle: true,
      clearWebView: true,
    );
  }

  void setSearchResults(List<SearchResult> results, String query) {
    state = state.copyWith(
      searchResults: results,
      currentQuery: query,
      isSearching: false,
      mode: WorkspaceMode.research,
    );
  }

  void setSearching(bool searching) {
    state = state.copyWith(isSearching: searching);
  }

  void selectArticle(SearchResult article) {
    state = state.copyWith(selectedArticle: article);
  }

  void clearSelectedArticle() {
    state = state.copyWith(clearSelectedArticle: true);
  }

  void openWebView(String url) {
    state = state.copyWith(
      webViewUrl: url,
      isWebViewMinimized: false,
    );
  }

  void closeWebView() {
    state = state.copyWith(clearWebView: true);
  }

  void minimizeWebView() {
    state = state.copyWith(isWebViewMinimized: true);
  }

  void maximizeWebView() {
    state = state.copyWith(isWebViewMinimized: false);
  }
}

final workspaceProvider = StateNotifierProvider<WorkspaceNotifier, WorkspaceState>((ref) {
  return WorkspaceNotifier();
});
