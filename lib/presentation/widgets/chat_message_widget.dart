import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:medicortex/utils/markdown_style.dart';

class ChatMessageWidget extends StatefulWidget {
  final String text;
  final bool isUser;
  final int timestamp;
  final Function(int)?
  onCitationTap; // Callback when citation [1], [2], etc. is tapped
  final VoidCallback? onRegenerate; // Callback to regenerate AI response
  final VoidCallback? onEdit; // Callback to edit user message
  final VoidCallback? onDelete; // Callback to delete message
  // PDF Export selection
  final bool isSelectionMode; // Whether in selection mode for PDF export
  final bool isSelected; // Whether this message is selected
  final Function(bool)?
  onSelectionChanged; // Callback when selection changes

  const ChatMessageWidget({
    super.key,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.onCitationTap,
    this.onRegenerate,
    this.onEdit,
    this.onDelete,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelectionChanged,
  });

  @override
  State<ChatMessageWidget> createState() => _ChatMessageWidgetState();
}

class _ChatMessageWidgetState extends State<ChatMessageWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: widget.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            widget.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              // Message container
              Container(
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.8,
                ),
                decoration: BoxDecoration(
                  color: widget.isUser ? theme.colorScheme.primary : null,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      widget.isUser
                          ? null
                          : Border.all(
                            color:
                                widget.isSelectionMode && widget.isSelected
                                    ? theme.colorScheme.primary
                                    : theme.dividerColor,
                            width: widget.isSelectionMode && widget.isSelected ? 2 : 1,
                          ),
                ),
                child:
                    widget.isUser
                        ? Text(
                          widget.text,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onPrimary,
                          ),
                        )
                        : _buildAIMessage(context),
              ),
              // Checkbox overlay for selection mode
              if (widget.isSelectionMode)
                Positioned(
                  top: 2,
                  left: widget.isUser ? null : 8,
                  right: widget.isUser ? 8 : null,
                  child: Material(
                    color: Colors.transparent,
                    child: Checkbox(
                      value: widget.isSelected,
                      onChanged: (value) {
                        widget.onSelectionChanged?.call(value ?? false);
                      },
                      activeColor: theme.colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
          // Message actions (hidden during selection mode)
          if (!widget.isSelectionMode) _buildMessageActions(context),
        ],
      ),
    );
  }

  Widget _buildMessageActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Copy button
          _ActionButton(
            icon: Icons.copy_rounded,
            tooltip: 'Copy',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: widget.text));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Copied to clipboard'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
          // Regenerate button (AI messages only)
          if (!widget.isUser && widget.onRegenerate != null)
            _ActionButton(
              icon: Icons.refresh_rounded,
              tooltip: 'Regenerate',
              onPressed: widget.onRegenerate,
            ),
          // Edit button (User messages only)
          if (widget.isUser && widget.onEdit != null) ...[
            const SizedBox(width: 4),
            _ActionButton(
              icon: Icons.edit_rounded,
              tooltip: 'Edit',
              onPressed: widget.onEdit,
            ),
          ],
          // Delete button (all messages)
          if (widget.onDelete != null) ...[
            const SizedBox(width: 4),
            _ActionButton(
              icon: Icons.delete_outline_rounded,
              tooltip: 'Delete',
              onPressed: widget.onDelete,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAIMessage(BuildContext context) {
    // Check if message is recent (within last 5 seconds) for streaming
    final isRecent = DateTime.fromMillisecondsSinceEpoch(
      widget.timestamp,
    ).isAfter(DateTime.now().subtract(const Duration(seconds: 2)));

    // Convert citations to markdown links for easy handling
    final processedText = _convertCitationsToLinks(widget.text);

    return MarkdownBody.streamLatex(
      data: processedText,
      shrinkWrap: true,
      streamingConfig:
          isRecent
              ? StreamingConfig(
                adaptiveBatching: true,
                batchUpdateInterval: const Duration(milliseconds: 100),
                typingSpeed: const Duration(milliseconds: 10),
                fadeInEnabled: true,
                fadeInDuration: const Duration(milliseconds: 100),
                fadeInCurve: Curves.easeOut,
                animationsEnabled: true,
              )
              : null,
      selectable: true,
      styleSheet: getMarkDownStyle(context),
      onTapLink: (text, href, title) {
        if (href != null && href.startsWith('citation:')) {
          // Extract citation index from href (e.g., "citation:1" or "citation:12345678")
          final citationStr = href.substring('citation:'.length);
          final citationIndex = int.tryParse(citationStr);
          if (citationIndex != null) {
            widget.onCitationTap?.call(citationIndex);
          }
        }
      },
    );
  }

  /// Convert citation formats to markdown links
  /// [1] -> [1](citation:1)
  /// [PMID: 12345678] -> [PMID: 12345678](citation:12345678)
  String _convertCitationsToLinks(String text) {
    final citationRegex = RegExp(
      r'\[PMID:\s*(\d+)\]|\[pmid:\s*(\d+)\]|\[(\d+)\]',
      caseSensitive: false,
    );

    return text.replaceAllMapped(citationRegex, (match) {
      final fullMatch = match.group(0)!;
      // Group 1: [PMID: xxx] (uppercase)
      // Group 2: [pmid: xxx] (lowercase)
      // Group 3: [xxx] (numeric)
      final pmidUppercase = match.group(1);
      final pmidLowercase = match.group(2);
      final numericCitation = match.group(3);

      int citationIndex;
      if (pmidUppercase != null) {
        citationIndex = int.parse(pmidUppercase);
      } else if (pmidLowercase != null) {
        citationIndex = int.parse(pmidLowercase);
      } else if (numericCitation != null) {
        citationIndex = int.parse(numericCitation);
      } else {
        return fullMatch; // Return unchanged if parsing fails
      }

      // Convert to markdown link: [text](citation:index)
      return '[$fullMatch](citation:$citationIndex)';
    });
  }
}

/// Action button widget for message actions
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.5,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            icon,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
