import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/chat_providers.dart';
import '../../providers/rag_provider.dart';
import '../../providers/search_providers.dart';
import '../../domains/ai/entity/ai_entities.dart';
import '../../domains/search/domain/entities/search_result.dart';
import '../providers/conversation_isar_provider.dart';
import '../providers/workspace_providers.dart';
import '../providers/selected_papers_provider.dart';
import '../providers/followup_questions_provider.dart';
import 'chat_message_widget.dart';
import 'medical_disclaimer_banner.dart';
import 'medicortex_logo.dart';
import '../../services/pdf_export_service.dart';

class AiChatPane extends ConsumerStatefulWidget {
  const AiChatPane({super.key});

  @override
  ConsumerState<AiChatPane> createState() => _AiChatPaneState();
}

class _AiChatPaneState extends ConsumerState<AiChatPane> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // PDF Export selection state
  bool _isSelectingMessages = false;
  final Set<int> _selectedMessageTimestamps = <int>{};

  @override
  void initState() {
    super.initState();
    // Listen to chat state changes to auto-scroll on new messages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listenManual(chatProvider, (previous, next) {
        // Auto-scroll when new messages arrive
        if (previous != null &&
            next.displayMessages.length > previous.displayMessages.length) {
          // Scroll to bottom when new message is added
          _scrollToBottom();
        }
      });
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        if (animate) {
          _scrollController.animateTo(
            maxScroll, // Scroll to bottom (max extent)
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController.jumpTo(maxScroll);
        }
      }
    });
  }

  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    _inputController.clear();
    ref.read(chatProvider.notifier).sendMessage(text);

    // Auto-scroll will be handled by the listener
  }

  void _handleDeleteMessage(int timestamp) {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Message'),
            content: const Text(
              'Are you sure you want to delete this message?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);

                  // Delete from UI state
                  ref.read(chatProvider.notifier).deleteMessage(timestamp);

                  // Delete from database if there's an active session
                  final sessionId = ref.read(currentSessionIdProvider);
                  if (sessionId != null) {
                    await ref
                        .read(conversationIsarProvider.notifier)
                        .deleteMessage(sessionId, timestamp);
                    debugPrint('🗑️  Deleted message from session $sessionId');
                  }

                  navigator.pop();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Message deleted'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  void _handleCitationTap(int citationIndex) {
    final workspaceState = ref.read(workspaceProvider);
    final results = workspaceState.searchResults;

    // Check if citationIndex is a PMID (large number) or a numeric citation (small number)
    final isPmid = citationIndex > 1000; // PMIDs are typically 8 digits

    if (isPmid) {
      // Handle PMID citation: [PMID: 12345678]
      final pmid = citationIndex.toString();

      // Check if paper is already in results
      final existingPaper =
          results.where((paper) => paper.id == pmid).firstOrNull;

      if (existingPaper != null) {
        // Paper exists in results - add to selection
        ref.read(selectedPapersProvider.notifier).togglePaper(pmid);

        final isSelected =
            ref
                .read(selectedPapersProvider)
                .firstWhereOrNull((paper) => paper == pmid) !=
            null;

        // Show feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              !isSelected
                  ? 'PMID: $pmid removed from selection'
                  : 'PMID: $pmid added to selection',
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: !isSelected ? Colors.black54 : Colors.green,
          ),
        );

        // Highlight the paper briefly
        ref.read(workspaceProvider.notifier).selectArticle(existingPaper);
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            ref.read(workspaceProvider.notifier).clearSelectedArticle();
          }
        });
      } else {
        // Paper not in results - fetch and add it
        _fetchAndAddPaper(pmid);
      }
    } else {
      // Handle numeric citation: [1], [2], etc.
      if (citationIndex > 0 && citationIndex <= results.length) {
        final article =
            results[citationIndex - 1]; // Convert 1-based to 0-based
        ref.read(workspaceProvider.notifier).selectArticle(article);

        // Clear selection after animation
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            ref.read(workspaceProvider.notifier).clearSelectedArticle();
          }
        });
      }
    }
  }

  Future<void> _fetchAndAddPaper(String pmid) async {
    // Show loading feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Fetching paper PMID: $pmid...'),
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      // Get Elasticsearch client directly for ID-based lookup
      final esClient = ref.read(elasticsearchClientProvider);

      // Fetch document by ID (PMID is used as document ID in Elasticsearch)
      final response = await esClient.getDocumentById(pmid);

      if (response != null) {
        // Convert to SearchResult
        final paper = SearchResult(
          id: pmid,
          title: response['title']?.toString() ?? '',
          abstract: response['abstract']?.toString() ?? '',
          score: 1.0,
          publicationDate:
              response['publication_date'] != null
                  ? DateTime.tryParse(response['publication_date'].toString())
                  : null,
          sourceUrl:
              response['source_url']?.toString() ??
              'https://pubmed.ncbi.nlm.nih.gov/$pmid/',
          authors: (response['authors'] as List?)?.cast<String>() ?? [],
          metadata: response,
        );

        // Add to current results
        final workspaceState = ref.read(workspaceProvider);
        final updatedResults = [...workspaceState.searchResults, paper];
        ref
            .read(workspaceProvider.notifier)
            .setSearchResults(
              updatedResults,
              workspaceState.currentQuery ?? '',
            );

        // Add to selection
        ref.read(selectedPapersProvider.notifier).togglePaper(pmid);

        // Show success
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added PMID: $pmid to results and selection'),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Highlight the paper
        ref.read(workspaceProvider.notifier).selectArticle(paper);
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            ref.read(workspaceProvider.notifier).clearSelectedArticle();
          }
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Paper PMID: $pmid not found'),
              backgroundColor: Theme.of(context).colorScheme.secondary,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching paper: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _exportSelectedMessages(List<dynamic> allMessages) async {
    try {
      debugPrint(
        '📄 Exporting ${_selectedMessageTimestamps.length} selected messages...',
      );

      // Filter messages to only selected ones
      final selectedMessages =
          allMessages
              .where(
                (msg) => _selectedMessageTimestamps.contains(msg.timestamp),
              )
              .toList();

      debugPrint('📄 Filtered to ${selectedMessages.length} messages');

      final workspaceState = ref.read(workspaceProvider);
      final selectedPapers = ref.read(selectedPapersProvider);
      final conversationTitle =
          workspaceState.currentQuery ?? 'Medical Research Conversation';

      debugPrint(
        '📄 Calling PdfExportService.saveAndDownload with selected messages...',
      );
      await PdfExportService.saveAndDownload(
        conversationTitle: conversationTitle,
        messages: selectedMessages.cast(),
        selectedPapers:
            selectedPapers.isNotEmpty ? selectedPapers.toList() : null,
      );

      // Exit selection mode and show success
      setState(() {
        _isSelectingMessages = false;
        _selectedMessageTimestamps.clear();
      });

      debugPrint('📄 PDF export completed successfully!');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'PDF exported with ${selectedMessages.length} messages!',
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ PDF Export Error: $e');
      debugPrint('❌ Stack trace:\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export PDF: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chatState = ref.watch(chatProvider);
    final messages = chatState.displayMessages;
    final isLoading = chatState.isLoading;
    final isRestoringConversation = ref.watch(isRestoringConversationProvider);
    final currentSessionId = ref.watch(currentSessionIdProvider);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(left: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        children: [
          // Medical disclaimer
          const MedicalDisclaimerBanner(),

          // Export button or selection mode controls
          if (messages.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color:
                    _isSelectingMessages
                        ? theme.colorScheme.primaryContainer
                        : theme.cardColor,
                border: Border(bottom: BorderSide(color: theme.dividerColor)),
              ),
              child:
                  _isSelectingMessages
                      ? Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_selectedMessageTimestamps.length} selected',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          // Select All button
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedMessageTimestamps.clear();
                                _selectedMessageTimestamps.addAll(
                                  messages.map((m) => m.timestamp),
                                );
                              });
                            },
                            icon: Icon(
                              Icons.select_all,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            label: Text(
                              'Select All',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Cancel button
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _isSelectingMessages = false;
                                _selectedMessageTimestamps.clear();
                              });
                            },
                            icon: Icon(
                              Icons.close,
                              size: 16,
                              color: theme.colorScheme.error,
                            ),
                            label: Text(
                              'Cancel',
                              style: TextStyle(
                                color: theme.colorScheme.onErrorContainer,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.icon(
                            onPressed:
                                _selectedMessageTimestamps.isEmpty
                                    ? null
                                    : () => _exportSelectedMessages(messages),
                            icon: const Icon(Icons.picture_as_pdf, size: 16),
                            label: const Text('Export'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      )
                      : Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            onPressed:
                                isLoading
                                    ? null
                                    : () {
                                      debugPrint(
                                        '📋 Entering selection mode with ${messages.length} messages',
                                      );
                                      // Check for duplicates
                                      final timestamps =
                                          messages
                                              .map((m) => m.timestamp)
                                              .toList();
                                      debugPrint(
                                        '📋 All message timestamps: $timestamps',
                                      );
                                      final uniqueTimestamps =
                                          timestamps.toSet();
                                      debugPrint(
                                        '📋 Unique timestamps: ${uniqueTimestamps.length}',
                                      );
                                      if (timestamps.length !=
                                          uniqueTimestamps.length) {
                                        debugPrint(
                                          '⚠️ WARNING: Duplicate timestamps found!',
                                        );
                                      }

                                      setState(() {
                                        _isSelectingMessages = true;
                                        // Pre-select only the last (most recent) message
                                        _selectedMessageTimestamps.clear();
                                        if (messages.isNotEmpty) {
                                          final lastTimestamp =
                                              messages.last.timestamp;
                                          debugPrint(
                                            '📋 Last message timestamp: $lastTimestamp',
                                          );
                                          _selectedMessageTimestamps.add(
                                            lastTimestamp,
                                          );
                                        }
                                        debugPrint(
                                          '📋 Pre-selected ${_selectedMessageTimestamps.length} message (last one)',
                                        );
                                        debugPrint(
                                          '📋 Timestamps: $_selectedMessageTimestamps',
                                        );
                                      });
                                    },
                            icon: const Icon(Icons.picture_as_pdf, size: 16),
                            label: const Text('Export to PDF'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
            ),

          // Chat messages
          Expanded(
            child:
                isRestoringConversation
                    ? _buildRestoringState(currentSessionId)
                    : messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                      controller: _scrollController,
                      //reverse: true, // WhatsApp-style: newest at bottom
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      itemCount: messages.length,
                      // Disable automatic scroll to bottom on content change
                      physics: const ClampingScrollPhysics(),
                      itemBuilder: (context, index) {
                        // Reverse the index to show newest messages at bottom
                        //final reversedIndex = messages.length - 1 - index;
                        final message = messages[index];
                        final isSelected = _selectedMessageTimestamps.contains(
                          message.timestamp,
                        );
                        if (_isSelectingMessages &&
                            index == messages.length - 1) {
                          debugPrint(
                            '📋 Building last message widget - index: $index, timestamp: ${message.timestamp}, isSelected: $isSelected',
                          );
                        }
                        return ChatMessageWidget(
                          key: ValueKey(
                            '${message.timestamp}_${message.text.hashCode}',
                          ),
                          text: message.text,
                          isUser: message.isUser,
                          onCitationTap: _handleCitationTap,
                          timestamp: message.timestamp,
                          onDelete:
                              () => _handleDeleteMessage(message.timestamp),
                          // PDF Export selection
                          isSelectionMode: _isSelectingMessages,
                          isSelected: isSelected,
                          onSelectionChanged: (selected) {
                            debugPrint(
                              '📋 Selection changed for message ${message.timestamp}: $selected',
                            );
                            setState(() {
                              if (selected) {
                                _selectedMessageTimestamps.add(
                                  message.timestamp,
                                );
                                debugPrint(
                                  '📋 Added. Total selected: ${_selectedMessageTimestamps.length}',
                                );
                                debugPrint(
                                  '📋 Selected timestamps: $_selectedMessageTimestamps',
                                );
                              } else {
                                _selectedMessageTimestamps.remove(
                                  message.timestamp,
                                );
                                debugPrint(
                                  '📋 Removed. Total selected: ${_selectedMessageTimestamps.length}',
                                );
                              }
                            });
                          },
                        );
                      },
                    ),
          ),

          // Loading indicator with dynamic status
          if (isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      chatState.loadingStatus,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          // Follow-up questions (tappable chips)
          _buildFollowUpQuestions(),

          // RAG action buttons (when papers are selected)
          _buildRagActionButtons(),

          // Input area
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildRestoringState(int? sessionId) {
    // Determine if this is a new session or resuming
    final isNewSession = sessionId == null;
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Medicortex logo
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.8 + (value * 0.2),
                  child: Opacity(
                    opacity: 0.3 + (value * 0.7),
                    child: const MedicortexLogo(size: 64),
                  ),
                );
              },
              onEnd: () {
                // Loop the animation
                if (mounted) {
                  setState(() {});
                }
              },
            ),
            const SizedBox(height: 24),
            Text(
              isNewSession
                  ? 'Initializing Medicortex...'
                  : 'Restoring conversation...',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isNewSession
                  ? 'Setting up your research session'
                  : 'Loading previous messages',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const MedicortexLogo(size: 64),
            const SizedBox(height: 24),
            Text(
              'Ask me anything about medical research',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'I can help you understand studies, compare treatments, and answer health questions.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: theme.dividerColor, width: 1),
              ),
              child: TextField(
                controller: _inputController,
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Ask about the research...',
                  hintStyle: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.hintColor,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_upward, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  /// Build follow-up questions as tappable chips
  Widget _buildFollowUpQuestions() {
    final theme = Theme.of(context);
    final questions = ref.watch(followUpQuestionsProvider);
    final isLoading = ref.watch(chatProvider).isLoading;

    if (questions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiary.withValues(alpha: 0.1),
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.tertiary.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 14,
                color: theme.colorScheme.tertiary,
              ),
              const SizedBox(width: 6),
              Text(
                'Follow-up Questions',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.tertiary,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  Icons.close,
                  size: 16,
                  color: theme.colorScheme.tertiary,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  ref.read(followUpQuestionsProvider.notifier).clearQuestions();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children:
                questions.map((question) {
                  return ActionChip(
                    label: Text(
                      question,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                    onPressed:
                        isLoading
                            ? null
                            : () {
                              // Send as user message
                              ref
                                  .read(chatProvider.notifier)
                                  .sendMessage(question);
                              // Clear questions after use
                              ref
                                  .read(followUpQuestionsProvider.notifier)
                                  .clearQuestions();
                            },
                    backgroundColor: theme.cardColor,
                    side: BorderSide(
                      color: theme.colorScheme.tertiary.withValues(alpha: 0.3),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  /// Build RAG action buttons for selected papers
  Widget _buildRagActionButtons() {
    final theme = Theme.of(context);
    final selectedCount = ref.watch(selectedPapersProvider).length;
    final chatState = ref.watch(chatProvider);
    final isLoading = chatState.isLoading;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '$selectedCount ${selectedCount == 1 ? 'paper' : 'papers'} selected',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed:
                    isLoading
                        ? null
                        : () {
                          ref
                              .read(selectedPapersProvider.notifier)
                              .clearSelection();
                        },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text('Clear', style: theme.textTheme.labelSmall),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Action buttons
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildRagButton(
                icon: Icons.summarize,
                label: 'Synthesize',
                onPressed:
                    isLoading ? null : () => _executeRagDirectly('synthesize'),
              ),
              _buildRagButton(
                icon: Icons.compare_arrows,
                label: 'Compare',
                onPressed:
                    isLoading || selectedCount < 2
                        ? null
                        : () => _executeRagDirectly('compare'),
              ),
              _buildRagButton(
                icon: Icons.insights,
                label: 'Insights',
                onPressed:
                    isLoading ? null : () => _executeRagDirectly('insights'),
              ),
              _buildRagButton(
                icon: Icons.lightbulb_outline,
                label: 'Follow-ups',
                onPressed:
                    isLoading ? null : () => _executeRagDirectly('followups'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRagButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    final theme = Theme.of(context);

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
        foregroundColor: theme.colorScheme.primary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }

  /// Execute RAG operations directly without going through AI
  Future<void> _executeRagDirectly(String action) async {
    final ragService = ref.read(ragServiceProvider);
    if (ragService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'RAG service not available. Please configure Gemini API key.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Get selected papers
    final selectedPmids = ref.read(selectedPapersProvider);
    final workspaceState = ref.read(workspaceProvider);
    final allResults = workspaceState.searchResults;
    final selectedPapers =
        allResults.where((paper) => selectedPmids.contains(paper.id)).toList();

    if (selectedPapers.isEmpty && action != 'followups') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No papers selected. Please select papers first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Set loading state
    ref.read(chatProvider.notifier).setLoading(true);

    try {
      String result;

      switch (action) {
        case 'synthesize':
          final query = workspaceState.currentQuery ?? 'medical research';
          result = await ragService.synthesizePapers(
            papers: selectedPapers,
            topic: query,
          );
          break;

        case 'compare':
          if (selectedPapers.length < 2) {
            throw Exception('Need at least 2 papers to compare.');
          }
          result = await ragService.compareStudies(
            papers: selectedPapers,
            comparisonAspect: 'methodology and findings',
          );
          break;

        case 'insights':
          final insights = await ragService.extractKeyInsights(selectedPapers);
          result =
              '**Key Insights:**\n\n${insights.asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('\n\n')}';
          break;

        case 'followups':
          List<String> questions;

          if (selectedPapers.isEmpty) {
            // Generate follow-ups based on chat history
            final chatHistory = ref.read(chatProvider).chatHistory;
            final recentMessages =
                chatHistory
                    .where((msg) => msg.role == 'user' || msg.role == 'model')
                    .take(10)
                    .toList();

            if (recentMessages.isEmpty) {
              throw Exception(
                'No conversation history to generate follow-ups from.',
              );
            }

            // Build context from recent messages
            final conversationContext = recentMessages
                .map((msg) {
                  final role = msg.role == 'user' ? 'User' : 'AI';
                  final text = msg.parts
                      .whereType<AiTextPart>()
                      .map((part) => part.text)
                      .join(' ');
                  return '$role: $text';
                })
                .join('\n\n');

            // Use RAG service to generate questions from conversation
            questions = await ragService.suggestFollowUpQuestions(
              originalQuery: conversationContext,
              papers: [], // Empty papers list
            );
          } else {
            // Generate follow-ups based on selected papers
            questions = await ragService.suggestFollowUpQuestions(
              originalQuery: workspaceState.currentQuery ?? '',
              papers: selectedPapers,
            );
          }

          // Store questions in provider for display as chips
          ref.read(followUpQuestionsProvider.notifier).setQuestions(questions);

          // Don't add to chat - only show in widget
          result = ''; // Empty result so nothing is added to chat
          break;

        default:
          throw Exception('Unknown action: $action');
      }

      // Add result as AI message (only if not empty)
      if (result.isNotEmpty) {
        ref.read(chatProvider.notifier).addAiMessage(result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      ref.read(chatProvider.notifier).setLoading(false);
    }
  }
}
