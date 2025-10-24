import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domains/search/domain/entities/search_result.dart';
import '../providers/selected_papers_provider.dart';

class ArticleCard extends ConsumerStatefulWidget {
  final SearchResult article;
  final bool isHighlighted;
  final VoidCallback onReadFull;
  final VoidCallback onAskAI;
  final Function(String)? onTextSelected;

  const ArticleCard({
    super.key,
    required this.article,
    this.isHighlighted = false,
    required this.onReadFull,
    required this.onAskAI,
    this.onTextSelected,
  });

  @override
  ConsumerState<ArticleCard> createState() => _ArticleCardState();
}

class _ArticleCardState extends ConsumerState<ArticleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _highlightController;
  late Animation<Color?> _highlightAnimation;

  @override
  void initState() {
    super.initState();
    _highlightController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _highlightAnimation = ColorTween(
      begin: Colors.yellow.withValues(alpha: 0.3),
      end: Colors.transparent,
    ).animate(_highlightController);
  }

  @override
  void didUpdateWidget(ArticleCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isHighlighted && !oldWidget.isHighlighted) {
      _highlightController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _highlightController.dispose();
    super.dispose();
  }

  String _formatAuthors() {
    if (widget.article.authors.isEmpty) return 'Unknown Authors';
    if (widget.article.authors.length == 1) return widget.article.authors[0];
    return '${widget.article.authors[0]} et al.';
  }

  String _formatDate() {
    if (widget.article.publicationDate == null) return 'Unknown';
    return widget.article.publicationDate!.year.toString();
  }

  String _truncateAbstract(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  void _copyCitation() {
    final citation =
        '${_formatAuthors()}. ${widget.article.title}. ${_formatDate()}. PMID: ${widget.article.id}';
    Clipboard.setData(ClipboardData(text: citation));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Citation copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _highlightAnimation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _highlightAnimation.value ?? Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: child,
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Selection checkbox and title row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Checkbox for paper selection
                Checkbox(
                  value: ref.watch(selectedPapersProvider).contains(widget.article.id),
                  onChanged: (selected) {
                    ref.read(selectedPapersProvider.notifier).togglePaper(widget.article.id);
                  },
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 8),
                // Title
                Expanded(
                  child: SelectableText(
                    widget.article.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    contextMenuBuilder: (context, editableTextState) {
                      final selectedText = editableTextState
                          .textEditingValue
                          .selection
                          .textInside(editableTextState.textEditingValue.text);

                      return AdaptiveTextSelectionToolbar.buttonItems(
                        anchors: editableTextState.contextMenuAnchors,
                        buttonItems: [
                          ...editableTextState.contextMenuButtonItems,
                          if (selectedText.isNotEmpty &&
                              widget.onTextSelected != null)
                            ContextMenuButtonItem(
                              onPressed: () {
                                ContextMenuController.removeAny();
                                widget.onTextSelected!(selectedText);
                              },
                              label: 'Ask AI about this',
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Authors and Year
            Text(
              '${_formatAuthors()} • ${_formatDate()}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 4),

            // PMID
            Text(
              'PMID: ${widget.article.id}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),

            // Abstract preview
            Expanded(
              child: SelectableText(
                _truncateAbstract(widget.article.abstract, 200),
                maxLines: 4,

                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  overflow: TextOverflow.ellipsis,
                ),
                contextMenuBuilder: (context, editableTextState) {
                  final selectedText = editableTextState
                      .textEditingValue
                      .selection
                      .textInside(editableTextState.textEditingValue.text);

                  return AdaptiveTextSelectionToolbar.buttonItems(
                    anchors: editableTextState.contextMenuAnchors,
                    buttonItems: [
                      ...editableTextState.contextMenuButtonItems,
                      if (selectedText.isNotEmpty &&
                          widget.onTextSelected != null)
                        ContextMenuButtonItem(
                          onPressed: () {
                            ContextMenuController.removeAny();
                            widget.onTextSelected!(selectedText);
                          },
                          label: 'Ask AI about this',
                        ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // Relevance score bar
            Row(
              children: [
                Text(
                  'Relevance: ',
                  style: theme.textTheme.bodySmall,
                ),
                Expanded(
                  child: LinearProgressIndicator(
                    value: (widget.article.score / 10).clamp(0.0, 1.0),
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getRelevanceColor(widget.article.score, theme),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(widget.article.score * 10).toStringAsFixed(0)}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                _ActionButton(
                  icon: Icons.open_in_new,
                  label: 'Read Full',
                  onPressed: widget.onReadFull,
                ),
                const SizedBox(width: 8),
                _ActionButton(
                  icon: Icons.content_copy,
                  label: 'Cite',
                  onPressed: _copyCitation,
                ),
                const SizedBox(width: 8),
                _ActionButton(
                  icon: Icons.psychology,
                  label: 'Ask AI',
                  onPressed: widget.onAskAI,
                  isPrimary: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getRelevanceColor(double score, ThemeData theme) {
    if (score > 7) return Colors.green;
    if (score > 4) return Colors.orange;
    return Colors.red;
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: isPrimary
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.primary,
          backgroundColor: isPrimary
              ? theme.colorScheme.primary
              : theme.cardColor,
          side: BorderSide(
            color: isPrimary
                ? theme.colorScheme.primary
                : theme.dividerColor,
          ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        ),
      ),
    );
  }
}
