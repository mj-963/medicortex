import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/search_history_provider.dart';

class SearchHistorySidebar extends ConsumerWidget {
  final Function(String query, int? conversationId) onSearchSelected;
  final VoidCallback onClose;

  const SearchHistorySidebar({
    super.key,
    required this.onSearchSelected,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(searchHistoryProvider);
    final theme = Theme.of(context);

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          left: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: theme.dividerColor)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.history,
                  size: 24,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Search History',
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  color: theme.iconTheme.color,
                  onPressed: onClose,
                  tooltip: 'Close',
                ),
              ],
            ),
          ),

          // History list
          Expanded(
            child:
                history.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: history.length,
                      itemBuilder: (context, index) {
                        final item = history[index];
                        return _HistoryItem(
                          item: item,
                          onTap: () {
                            onSearchSelected(item.query, item.conversationId);
                            onClose();
                          },
                          onDelete: () {
                            if (item.conversationId != null) {
                              ref
                                  .read(searchHistoryProvider.notifier)
                                  .removeSearch(item.conversationId!);
                            }
                          },
                        );
                      },
                    ),
          ),

          // Clear all button
          if (history.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: theme.dividerColor)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showClearConfirmation(context, ref);
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Clear All History'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    side: BorderSide(color: theme.colorScheme.error),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 64,
                  color: theme.iconTheme.color?.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No search history yet',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Your recent searches will appear here',
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showClearConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clear Search History?'),
            content: const Text(
              'This will permanently delete all your search history. This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  ref.read(searchHistoryProvider.notifier).clearHistory();
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Clear All'),
              ),
            ],
          ),
    );
  }
}

class _HistoryItem extends StatefulWidget {
  final SearchHistoryItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _HistoryItem({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_HistoryItem> createState() => _HistoryItemState();
}

class _HistoryItemState extends State<_HistoryItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _isHovered
                ? theme.colorScheme.primary.withValues(alpha: 0.05)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(
                Icons.search,
                size: 20,
                color: theme.iconTheme.color,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.query,
                      style: theme.textTheme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          widget.item.timeAgo,
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color
                                ?.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.item.resultCount} results',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_isHovered)
                IconButton(
                  icon: Icon(
                    Icons.close,
                    size: 18,
                    color: theme.iconTheme.color,
                  ),
                  onPressed: widget.onDelete,
                  tooltip: 'Remove',
                ),
            ],
          ),
        ),
      ),
    );
  }
}
