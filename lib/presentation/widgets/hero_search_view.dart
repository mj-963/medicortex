import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/theme_provider.dart';
import '../providers/search_history_provider.dart';
import 'medicortex_logo.dart';
import 'search_history_sidebar.dart';

class HeroSearchView extends ConsumerStatefulWidget {
  final Function(String, {bool sendToAI, int? resumeSessionId}) onSearch;

  const HeroSearchView({super.key, required this.onSearch});

  @override
  ConsumerState<HeroSearchView> createState() => _HeroSearchViewState();
}

class _HeroSearchViewState extends ConsumerState<HeroSearchView> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey _textFieldKey = GlobalKey();
  final FocusNode _searchFocusNode = FocusNode();
  bool _showHistory = false;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  double getBorderRadius() {
    final RenderBox? renderBox =
        _textFieldKey.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox == null) return 50.0;

    final currentHeight = renderBox.size.height;
    final textStyle =
        Theme.of(context).textTheme.bodyLarge ?? const TextStyle(fontSize: 16);
    final singleLineHeight = textStyle.fontSize! * 1.5;

    const double maxRadius = 50.0;
    const double minRadius = 20.0;
    double maxHeight = singleLineHeight * 5;

    final ratio =
        (currentHeight - singleLineHeight) / (maxHeight - singleLineHeight);
    final radius = maxRadius - (ratio * (maxRadius - minRadius));

    return radius.clamp(minRadius, maxRadius);
  }

  void _handleSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      widget.onSearch(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final searchHistory = ref.watch(searchHistoryProvider);
    final recentSearches = searchHistory.take(3).toList();

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () {
          _searchFocusNode.requestFocus();
        },
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): () {
          _searchFocusNode.requestFocus();
        },
        const SingleActivator(LogicalKeyboardKey.keyH, meta: true): () {
          setState(() => _showHistory = !_showHistory);
        },
        const SingleActivator(LogicalKeyboardKey.keyH, control: true): () {
          setState(() => _showHistory = !_showHistory);
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: Stack(
            children: [
              // Centered Search and Chips
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search Bar
                    Container(
                      constraints: const BoxConstraints(maxWidth: 640),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(getBorderRadius()),
                        border: Border.all(
                          color: theme.dividerColor,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search,
                            color: theme.iconTheme.color,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              key: _textFieldKey,
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              minLines: 1,
                              maxLines: 5,
                              onSubmitted: (_) => _handleSearch(),
                              style: theme.textTheme.bodyLarge,
                              decoration: InputDecoration(
                                hintText: "Search medical literature...",
                                hintStyle: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.hintColor,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_upward),
                              color: Colors.white,
                              iconSize: 20,
                              onPressed: _handleSearch,
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Recent Search Chips
                    if (recentSearches.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Container(
                        constraints: const BoxConstraints(maxWidth: 640),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: recentSearches.map((item) {
                            return ActionChip(
                              avatar: Icon(
                                Icons.history,
                                size: 16,
                                color: theme.textTheme.bodySmall?.color,
                              ),
                              label: Text(
                                item.query.length > 40
                                    ? '${item.query.substring(0, 40)}...'
                                    : item.query,
                                style: theme.textTheme.bodyMedium,
                              ),
                              onPressed: () {
                                _searchController.text = item.query;
                                if (item.conversationId != null) {
                                  widget.onSearch(
                                    item.query,
                                    sendToAI: false,
                                    resumeSessionId: item.conversationId,
                                  );
                                } else {
                                  _handleSearch();
                                }
                              },
                              backgroundColor: theme.chipTheme.backgroundColor,
                              side: BorderSide(
                                color: theme.dividerColor,
                                width: 1,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Top-left Medicortex branding
              Positioned(
                top: 30,
                left: 30,
                child: Material(
                  color: theme.cardColor,
                  elevation: 0,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: theme.dividerColor,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const MedicortexLogo(size: 24),
                        const SizedBox(width: 8),
                        Text(
                          "Medicortex",
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Top-right icons (History + Settings)
              Positioned(
                top: 30,
                right: 30,
                child: Row(
                  children: [
                    // History button
                    Material(
                      color: theme.cardColor,
                      elevation: 0,
                      shape: const CircleBorder(),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.dividerColor,
                            width: 1,
                          ),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.history),
                          color: theme.iconTheme.color,
                          iconSize: 20,
                          onPressed: () {
                            setState(() => _showHistory = true);
                          },
                          tooltip: 'Search History',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Theme toggle button
                    Material(
                      color: theme.cardColor,
                      elevation: 0,
                      shape: const CircleBorder(),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.dividerColor,
                            width: 1,
                          ),
                        ),
                        child: IconButton(
                          icon: Icon(
                            theme.brightness == Brightness.light
                                ? Icons.dark_mode_outlined
                                : Icons.light_mode_outlined,
                          ),
                          color: theme.iconTheme.color,
                          iconSize: 20,
                          onPressed: () {
                            ref.read(themeModeProvider.notifier).toggleTheme();
                          },
                          tooltip: 'Toggle Theme',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Analytics button
                    Material(
                      color: theme.cardColor,
                      elevation: 0,
                      shape: const CircleBorder(),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.dividerColor,
                            width: 1,
                          ),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.analytics_outlined),
                          color: theme.iconTheme.color,
                          iconSize: 20,
                          onPressed: () {
                            Navigator.pushNamed(context, '/analytics');
                          },
                          tooltip: 'Analytics Dashboard',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Settings button
                    Material(
                      color: theme.cardColor,
                      elevation: 0,
                      shape: const CircleBorder(),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.dividerColor,
                            width: 1,
                          ),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.settings),
                          color: theme.iconTheme.color,
                          iconSize: 20,
                          onPressed: () {
                            Navigator.pushNamed(context, '/settings');
                          },
                          tooltip: 'Settings',
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom-right info
              Positioned(
                bottom: 24,
                right: 30,
                child: Row(
                  children: [
                    TextButton.icon(
                      icon: Icon(
                        Icons.lightbulb_outline,
                        size: 16,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                      label: Text(
                        'Cmd+K to search',
                        style: theme.textTheme.labelSmall,
                      ),
                      onPressed: () {
                        _searchFocusNode.requestFocus();
                      },
                    ),
                  ],
                ),
              ),

              // Search history sidebar
              if (_showHistory)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: SearchHistorySidebar(
                    onSearchSelected: (query, conversationId) {
                      _searchController.text = query;
                      // When resuming from history, restore the conversation
                      widget.onSearch(
                        query,
                        sendToAI: false,
                        resumeSessionId: conversationId,
                      );
                    },
                    onClose: () {
                      setState(() => _showHistory = false);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
