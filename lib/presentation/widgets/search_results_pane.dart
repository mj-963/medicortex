import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../domains/search/domain/entities/search_result.dart';
import '../../domains/search/domain/entities/search_query.dart';
import '../../providers/search_providers.dart';
import '../providers/conversation_isar_provider.dart';
import '../providers/workspace_providers.dart';
import '../providers/selected_papers_provider.dart';
import 'article_card.dart';
import 'filter_bar.dart';
import 'webview_overlay.dart';
import 'shimmer_loading.dart';

class SearchResultsPane extends ConsumerStatefulWidget {
  final List<SearchResult> results;
  final bool isLoading;
  final String? query;
  final Function(String) onAskAI;

  const SearchResultsPane({
    super.key,
    required this.results,
    required this.isLoading,
    this.query,
    required this.onAskAI,
  });

  @override
  ConsumerState<SearchResultsPane> createState() => _SearchResultsPaneState();
}

class _SearchResultsPaneState extends ConsumerState<SearchResultsPane> {
  String _sortBy = 'Relevance'; // Match FilterBar default
  String? _filterYear;
  String? _filterType;
  List<SearchResult> _filteredResults = [];
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isRefineMode = true; // Toggle for refine vs new search

  @override
  void initState() {
    super.initState();
    _filteredResults = widget.results;
    // Don't set search controller text - let it start empty
    // This prevents stale filters when restoring from history
  }

  @override
  void didUpdateWidget(SearchResultsPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.results != oldWidget.results) {
      // Reset filters when results change (e.g., from history)
      setState(() {
        _searchController.clear();
        _filterYear = null;
        _filterType = null;
        _sortBy = 'Relevance';
        _isRefineMode = true;
      });
      _applyFiltersAndSort();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _handleTextSelection(String text) {
    // Send directly to AI via context menu
    widget.onAskAI('Tell me more about: "$text"');
  }

  void _applyFiltersAndSort() {
    List<SearchResult> results = List.from(widget.results);

    // Apply search refinement first
    if (_searchController.text.trim().isNotEmpty) {
      final searchLower = _searchController.text.toLowerCase();
      results =
          results.where((article) {
            return article.title.toLowerCase().contains(searchLower) ||
                article.abstract.toLowerCase().contains(searchLower) ||
                article.authors.any(
                  (author) => author.toLowerCase().contains(searchLower),
                );
          }).toList();
    }

    // Apply year filter (skip if 'All Years' or null)
    if (_filterYear != null &&
        _filterYear != 'All Years' &&
        !_filterYear!.startsWith('Last')) {
      results =
          results.where((article) {
            return article.publicationDate?.year.toString() == _filterYear;
          }).toList();
    } else if (_filterYear == 'Last 5 years') {
      final fiveYearsAgo = DateTime.now().year - 5;
      results =
          results.where((article) {
            return article.publicationDate != null &&
                article.publicationDate!.year >= fiveYearsAgo;
          }).toList();
    }

    // Apply type filter (skip if 'All Types' or null)
    if (_filterType != null && _filterType != 'All Types') {
      results =
          results.where((article) {
            // Check if type exists in metadata
            final publicationType =
                article.metadata['publicationType'] as String?;
            if (publicationType == null) return false;

            // Match filter type with publication type
            final filterLower = _filterType!.toLowerCase();
            final typeLower = publicationType.toLowerCase();

            // Handle different type variations
            if (filterLower.contains('clinical trial')) {
              return typeLower.contains('clinical trial');
            } else if (filterLower.contains('meta-analysis')) {
              return typeLower.contains('meta-analysis') ||
                  typeLower.contains('meta analysis');
            } else if (filterLower.contains('review')) {
              return typeLower.contains('review');
            } else if (filterLower.contains('randomized')) {
              return typeLower.contains('randomized') ||
                  typeLower.contains('rct');
            }

            // Default: check if filter type is contained in publication type
            return typeLower.contains(filterLower);
          }).toList();
    }

    // Apply sorting
    switch (_sortBy.toLowerCase()) {
      case 'relevance':
        results.sort((a, b) => b.score.compareTo(a.score));
        break;
      case 'date (newest)':
        results.sort((a, b) {
          if (a.publicationDate == null) return 1;
          if (b.publicationDate == null) return -1;
          return b.publicationDate!.compareTo(a.publicationDate!);
        });
        break;
      case 'date (oldest)':
        results.sort((a, b) {
          if (a.publicationDate == null) return 1;
          if (b.publicationDate == null) return -1;
          return a.publicationDate!.compareTo(b.publicationDate!);
        });
        break;
      case 'citation count':
        // TODO: Implement when citation count is available
        results.sort(
          (a, b) => b.score.compareTo(a.score),
        ); // Fallback to relevance
        break;
    }

    setState(() {
      _filteredResults = results;
    });
  }

  void _clearAllFilters() {
    setState(() {
      _filterYear = null;
      _filterType = null;
      _sortBy = 'Relevance'; // Match FilterBar default
      _searchController.clear();
      _filteredResults = widget.results;
    });
    _applyFiltersAndSort();
  }

  Future<void> _exportResults() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now()
          .toIso8601String()
          .split('.')[0]
          .replaceAll(':', '-');
      final file = File('${directory.path}/medicortex_results_$timestamp.csv');

      final buffer = StringBuffer();
      buffer.writeln('PMID,Title,Authors,Year,Score,Abstract,URL');

      for (final article in _filteredResults) {
        final authors = article.authors.join('; ');
        final year = article.publicationDate?.year ?? 'N/A';
        final abstract = article.abstract.replaceAll('"', '""');
        buffer.writeln(
          '"${article.id}","${article.title}","$authors","$year","${article.score}","$abstract","${article.sourceUrl}"',
        );
      }

      await file.writeAsString(buffer.toString());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Exported ${_filteredResults.length} results to ${file.path}',
            ),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(label: 'OK', onPressed: () {}),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final workspaceState = ref.watch(workspaceProvider);
    final selectedArticle = workspaceState.selectedArticle;
    final webViewUrl = workspaceState.webViewUrl;
    final isWebViewMinimized = workspaceState.isWebViewMinimized;

    return Stack(
      children: [
        // Main content: Search bar + filters + results
        Column(
          children: [
            // Search bar at top
            _buildSearchBar(context),

            // Statistics and controls bar
            _buildStatisticsBar(),

            // Selection controls bar
            if (_filteredResults.isNotEmpty) _buildSelectionControlsBar(),

            // Filter bar
            FilterBar(
              selectedYear: _filterYear,
              selectedType: _filterType,
              selectedSort: _sortBy,
              onYearChanged: (year) {
                setState(() => _filterYear = year);
                _applyFiltersAndSort();
              },
              onTypeChanged: (type) {
                setState(() => _filterType = type);
                _applyFiltersAndSort();
              },
              onSortChanged: (sort) {
                setState(() => _sortBy = sort ?? '');
                _applyFiltersAndSort();
              },
            ),

            // Results grid
            Expanded(child: _buildResultsGrid(selectedArticle)),
          ],
        ),

        // WebView overlay (when active)
        if (webViewUrl != null)
          if (isWebViewMinimized)
            // Minimized view - already has Positioned in _buildMinimizedView
            WebViewOverlay(
              url: webViewUrl,
              isMinimized: true,
              onClose: () {
                ref.read(workspaceProvider.notifier).closeWebView();
              },
              onMinimize: () {
                ref.read(workspaceProvider.notifier).maximizeWebView();
              },
              onAskAI: widget.onAskAI,
            )
          else
            // Full view - needs Positioned.fill to cover entire pane
            Positioned.fill(
              child: WebViewOverlay(
                url: webViewUrl,
                isMinimized: false,
                onClose: () {
                  ref.read(workspaceProvider.notifier).closeWebView();
                },
                onMinimize: () {
                  ref.read(workspaceProvider.notifier).minimizeWebView();
                },
                onAskAI: widget.onAskAI,
              ),
            ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: theme.iconTheme.color),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          style: theme.textTheme.bodyLarge,
                          decoration: InputDecoration(
                            hintText: _isRefineMode
                                ? 'Refine search...'
                                : 'New search...',
                            border: InputBorder.none,
                            hintStyle: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                          onChanged: (value) {
                            if (_isRefineMode) {
                              // Apply filter on every keystroke in refine mode
                              _applyFiltersAndSort();
                            }
                          },
                          onSubmitted: (value) {
                            if (_isRefineMode) {
                              _applyFiltersAndSort();
                            } else {
                              // Perform new search
                              _performNewSearch(value);
                            }
                          },
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            if (_isRefineMode) {
                              _applyFiltersAndSort();
                            }
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Close button
              FilledButton.icon(
                onPressed: () {
                  debugPrint('⬅️  Closing session (Close button pressed)');
                  // Clear selected papers
                  ref.read(selectedPapersProvider.notifier).clearSelection();
                  // Clear current session when going back to hero
                  final currentSession = ref.read(currentSessionIdProvider);
                  if (currentSession != null) {
                    debugPrint(
                      '   Session $currentSession closed (stays in storage)',
                    );
                    ref.read(currentSessionIdProvider.notifier).state = null;
                  }
                  ref.read(workspaceProvider.notifier).switchToHeroMode();
                },
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Close'),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
          // Toggle for refine mode
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                _isRefineMode ? Icons.filter_alt : Icons.search,
                size: 16,
                color: theme.iconTheme.color,
              ),
              const SizedBox(width: 8),
              Text(
                _isRefineMode ? 'Refine Mode' : 'New Search Mode',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: _isRefineMode,
                onChanged: (value) {
                  setState(() {
                    _isRefineMode = value;
                    if (!value) {
                      // Switching to new search mode - clear the search field
                      _searchController.clear();
                    }
                  });
                },
                // activeTrackColor removed for Flutter 3.32 compatibility
                // In Flutter 3.32+, use default Material 3 styling instead
              ),
              const Spacer(),
              Text(
                _isRefineMode
                    ? 'Filter current results'
                    : 'Search all literature',
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _performNewSearch(String query) async {
    if (query.trim().isEmpty) return;

    // Set searching state
    ref.read(workspaceProvider.notifier).setSearching(true);

    try {
      // Get search repository
      final searchRepo = ref.read(searchRepositoryProvider);
      
      // Perform search
      final searchResults = await searchRepo.search(
        SearchQuery(query: query, maxResults: 20),
      );
      
      // Update workspace with new results
      ref
          .read(workspaceProvider.notifier)
          .setSearchResults(searchResults.results, query);
      
      // Update local state - reset everything for fresh search
      setState(() {
        _filteredResults = searchResults.results;
        _searchController.clear(); // Clear search field after new search
        _filterYear = null;
        _filterType = null;
        _sortBy = 'Relevance';
        _isRefineMode = true; // Reset to refine mode
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      ref.read(workspaceProvider.notifier).setSearching(false);
    }
  }

  Widget _buildStatisticsBar() {
    final theme = Theme.of(context);
    final hasActiveFilters =
        _filterYear != null && _filterYear != 'All Years' ||
        _filterType != null && _filterType != 'All Types' ||
        _searchController.text.isNotEmpty ||
        _sortBy != 'Relevance';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.5),
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.article_outlined,
            size: 18,
            color: theme.iconTheme.color,
          ),
          const SizedBox(width: 8),
          Text(
            '${_filteredResults.length} ${_filteredResults.length == 1 ? 'result' : 'results'}',
            style: theme.textTheme.titleSmall,
          ),
          if (_filteredResults.length != widget.results.length) ...[
            Text(
              ' (filtered from ${widget.results.length})',
              style: theme.textTheme.bodySmall,
            ),
          ],
          const Spacer(),
          // Clear filters button
          if (hasActiveFilters)
            TextButton.icon(
              onPressed: _clearAllFilters,
              icon: const Icon(Icons.clear_all, size: 16),
              label: const Text('Clear Filters'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                textStyle: const TextStyle(fontSize: 13),
              ),
            ),
          if (hasActiveFilters) const SizedBox(width: 8),
          // Export button
          OutlinedButton.icon(
            onPressed: _filteredResults.isEmpty ? null : _exportResults,
            icon: const Icon(Icons.download, size: 16),
            label: const Text('Export CSV'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsGrid(SearchResult? selectedArticle) {
    if (widget.isLoading) {
      return _buildLoadingState();
    }

    if (_filteredResults.isEmpty) {
      return _buildEmptyState();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        // --- Determine number of columns ---
        int crossAxisCount;
        if (width > 1600) {
          crossAxisCount = 4;
        } else if (width > 1200) {
          crossAxisCount = 3;
        } else if (width > 800) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 1;
        }

        // --- Dynamically calculate aspect ratio ---
        final targetRows =
            width > 1200
                ? 3.5
                : width > 800
                ? 3
                : 2.6;

        final itemWidth = width / crossAxisCount;
        final itemHeight = height / targetRows;

        // Base aspect ratio = width / height
        double childAspectRatio = itemWidth / itemHeight;

        // Optional tuning (for better card proportions)
        childAspectRatio *= .6;

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: _filteredResults.length,
          itemBuilder: (context, index) {
            final article = _filteredResults[index];
            final isHighlighted = selectedArticle?.id == article.id;

            return ArticleCard(
              article: article,
              isHighlighted: isHighlighted,
              onReadFull: () {
                ref
                    .read(workspaceProvider.notifier)
                    .openWebView(article.sourceUrl);
              },
              onAskAI: () {
                widget.onAskAI(
                  'Can you explain this study: "${article.title}" (PMID: ${article.id})?',
                );
              },
              onTextSelected: _handleTextSelection,
            );
          },
        );
      },
    );
  }

  Widget _buildLoadingState() {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate number of columns and aspect ratio based on width
        int crossAxisCount;
        double childAspectRatio;

        if (constraints.maxWidth > 1600) {
          crossAxisCount = 4;
          childAspectRatio = 0.7;
        } else if (constraints.maxWidth > 1200) {
          crossAxisCount = 3;
          childAspectRatio = 0.72;
        } else if (constraints.maxWidth > 900) {
          crossAxisCount = 2;
          childAspectRatio = 0.75;
        } else if (constraints.maxWidth > 600) {
          crossAxisCount = 2;
          childAspectRatio = 0.65;
        } else {
          crossAxisCount = 1;
          childAspectRatio = 0.85;
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: 8,
          itemBuilder: (context, index) {
            return ShimmerLoading(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadowColor.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Checkbox + Title row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(
                          width: 18,
                          height: 18,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ShimmerBox(
                                width: double.infinity,
                                height: 22,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              const SizedBox(height: 6),
                              ShimmerBox(
                                width: double.infinity,
                                height: 22,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Authors & Year
                    ShimmerBox(
                      width: 200,
                      height: 14,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 4),
                    // PMID
                    ShimmerBox(
                      width: 120,
                      height: 13,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 12),
                    // Abstract (4 lines)
                    ShimmerBox(
                      width: double.infinity,
                      height: 14,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 6),
                    ShimmerBox(
                      width: double.infinity,
                      height: 14,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 6),
                    ShimmerBox(
                      width: double.infinity,
                      height: 14,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 6),
                    ShimmerBox(
                      width: 180,
                      height: 14,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 12),
                    // Relevance score bar
                    Row(
                      children: [
                        ShimmerBox(
                          width: 70,
                          height: 12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: ShimmerBox(
                            width: double.infinity,
                            height: 4,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ShimmerBox(
                          width: 35,
                          height: 12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Action buttons (3 buttons)
                    Row(
                      children: [
                        ShimmerBox(
                          width: 95,
                          height: 36,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        const SizedBox(width: 8),
                        ShimmerBox(
                          width: 70,
                          height: 36,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        const SizedBox(width: 8),
                        ShimmerBox(
                          width: 80,
                          height: 36,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: theme.iconTheme.color?.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No articles found',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Try different keywords or filters',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  /// Build Selection Controls Bar
  Widget _buildSelectionControlsBar() {
    final theme = Theme.of(context);
    final selectedCount = ref.watch(selectedPapersProvider).length;
    final hasSelection = selectedCount > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: hasSelection
            ? theme.colorScheme.primary.withValues(alpha: 0.1)
            : theme.colorScheme.surface.withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(
            color: hasSelection
                ? theme.colorScheme.primary.withValues(alpha: 0.3)
                : theme.dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          // Hybrid search indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bolt,
                  size: 14,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Hybrid Search',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Selection count
          Icon(
            hasSelection ? Icons.check_circle : Icons.check_circle_outline,
            size: 18,
            color: hasSelection
                ? theme.colorScheme.primary
                : theme.iconTheme.color,
          ),
          const SizedBox(width: 8),
          Text(
            hasSelection
                ? '$selectedCount ${selectedCount == 1 ? 'paper' : 'papers'} selected'
                : 'Select papers to analyze with AI',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: hasSelection
                  ? theme.colorScheme.primary
                  : theme.textTheme.bodyMedium?.color,
            ),
          ),
          const Spacer(),
          // Selection actions
          if (hasSelection) ...[
            TextButton.icon(
              onPressed: () {
                ref.read(selectedPapersProvider.notifier).clearSelection();
              },
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('Clear'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
          ] else ...[
            TextButton.icon(
              onPressed: () {
                final pmids = _filteredResults.map((r) => r.id).toList();
                ref.read(selectedPapersProvider.notifier).selectAll(pmids);
              },
              icon: const Icon(Icons.select_all, size: 16),
              label: const Text('Select All'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
