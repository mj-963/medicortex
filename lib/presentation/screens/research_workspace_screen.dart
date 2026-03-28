import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domains/chat/entity/chat_state.dart';
import '../../domains/search/domain/entities/search_query.dart';
import '../../providers/chat_providers.dart';
import '../../providers/search_providers.dart';
import '../providers/conversation_isar_provider.dart';
import '../providers/search_history_provider.dart';
import '../providers/workspace_providers.dart';
import '../widgets/ai_chat_pane.dart';
import '../widgets/hero_search_view.dart';
import '../widgets/search_results_pane.dart';

class ResearchWorkspaceScreen extends ConsumerStatefulWidget {
  const ResearchWorkspaceScreen({super.key});

  @override
  ConsumerState<ResearchWorkspaceScreen> createState() =>
      _ResearchWorkspaceScreenState();
}

class _ResearchWorkspaceScreenState
    extends ConsumerState<ResearchWorkspaceScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _transitionController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _transitionController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _transitionController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _transitionController.dispose();
    super.dispose();
  }

  Future<void> _handleSearch(
    String query, {
    bool sendToAI = true,
    int? resumeSessionId,
  }) async {
    if (query.trim().isEmpty) return;

    // Show loading state immediately for chat pane
    ref.read(isRestoringConversationProvider.notifier).state = true;

    // Switch to research mode and show loading
    ref.read(workspaceProvider.notifier).switchToResearchMode();
    ref.read(workspaceProvider.notifier).setSearching(true);

    // Trigger transition animation
    _transitionController.forward();

    try {
      // Perform search
      final searchRepo = ref.read(searchRepositoryProvider);
      final results = await searchRepo.search(
        SearchQuery(query: query, maxResults: 20),
      );

      // Update state with results
      if (mounted) {
        ref
            .read(workspaceProvider.notifier)
            .setSearchResults(results.results, query);

        int sessionId;

        // Check if we're resuming an existing session or creating new
        if (resumeSessionId != null) {
          // RESUMING from history
          sessionId = resumeSessionId;
          debugPrint('📂 Resuming session $sessionId');

          // Get messages from Isar
          final messages = await ref
              .read(conversationIsarProvider.notifier)
              .getMessages(sessionId);

          if (messages.isNotEmpty) {
            debugPrint('   Found ${messages.length} messages to restore');
            // Set session as active
            ref.read(currentSessionIdProvider.notifier).state = sessionId;
            
            // Restore all messages
            ref.read(chatProvider.notifier).restoreMessages(messages);
            
            // Hide loading state after messages are restored
            await Future.delayed(const Duration(milliseconds: 300));
            if (mounted) {
              ref.read(isRestoringConversationProvider.notifier).state = false;
            }
          } else {
            debugPrint('   ⚠️ No messages found for session!');
            ref.read(currentSessionIdProvider.notifier).state = sessionId;
            // No messages to restore, hide loading immediately
            if (mounted) {
              ref.read(isRestoringConversationProvider.notifier).state = false;
            }
          }
        } else {
          // NEW SESSION - always create fresh
          debugPrint('✨ Creating NEW session for: $query');

          // Clear old chat messages first
          ref.read(chatProvider.notifier).clearChat();

          // Persist session — failure is non-fatal, AI still runs
          try {
            sessionId = await ref
                .read(conversationIsarProvider.notifier)
                .createSession(query, results.results);
            debugPrint('   Session ID: $sessionId');
          } catch (e) {
            debugPrint('⚠️ Could not persist session (DB unavailable): $e');
            sessionId = DateTime.now().millisecondsSinceEpoch;
          }

          // Set as active session
          ref.read(currentSessionIdProvider.notifier).state = sessionId;

          // Hide loading state for new session
          if (mounted) {
            ref.read(isRestoringConversationProvider.notifier).state = false;
          }

          // Send initial message to AI if requested
          if (sendToAI) {
            ref.read(chatProvider.notifier).sendMessage(query);
          }
        }

        // Save to search history with conversation ID
        ref
            .read(searchHistoryProvider.notifier)
            .addSearch(
              query,
              results.results.length,
              conversationId: sessionId,
            );
      }
    } catch (e) {
      debugPrint('Search error: $e');
      if (mounted) {
        ref.read(workspaceProvider.notifier).setSearching(false);
        // Hide loading state on error
        ref.read(isRestoringConversationProvider.notifier).state = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleAskAI(String message) {
    ref.read(chatProvider.notifier).sendMessage(message);
  }

  @override
  Widget build(BuildContext context) {
    final workspaceState = ref.watch(workspaceProvider);
    final isHeroMode = workspaceState.mode == WorkspaceMode.hero;

    // Listen to chat messages and save them to the current conversation
    ref.listen<ChatState>(chatProvider, (previous, next) {
      // Don't save if we're restoring messages
      final isRestoring = ref.read(isRestoringConversationProvider);
      if (isRestoring) {
        debugPrint('⏭️  Skipping save - restoring messages');
        return;
      }

      final sessionId = ref.read(currentSessionIdProvider);
      if (sessionId == null) {
        debugPrint('⏭️  No active session - not saving');
        return;
      }

      final prevLength = previous?.displayMessages.length ?? 0;
      final nextLength = next.displayMessages.length;
      // final prevMessages = previous?.displayMessages ?? [];
      final nextMessages = next.displayMessages;

      // Check if a new message was added
      if (nextLength > prevLength && nextLength > 0) {
        final newMessage = nextMessages.last;

        // Don't save empty placeholder messages (AI responses being streamed)
        if (newMessage.text.isEmpty) {
          debugPrint('⏭️  Skipping save - empty placeholder message');
          return;
        }

        final preview =
            newMessage.text.length > 40
                ? '${newMessage.text.substring(0, 40)}...'
                : newMessage.text;
        final sender = newMessage.isUser ? '👤 User' : '🤖 AI';
        debugPrint('💾 Saving [$sender]: $preview');
        debugPrint('   → Session: $sessionId');
        ref
            .read(conversationIsarProvider.notifier)
            .addMessage(sessionId, newMessage);
      }
    });

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (!isHeroMode) {
            debugPrint('⬅️  Closing session (Esc pressed)');
            // Clear current session when going back to hero
            final currentSession = ref.read(currentSessionIdProvider);
            if (currentSession != null) {
              debugPrint(
                '   Session $currentSession closed (stays in storage)',
              );
              ref.read(currentSessionIdProvider.notifier).state = null;
            }
            ref.read(workspaceProvider.notifier).switchToHeroMode();
            _transitionController.reverse();
          }
        },
        const SingleActivator(LogicalKeyboardKey.keyN, meta: true): () {
          debugPrint('⬅️  Closing session (Cmd+N pressed)');
          final currentSession = ref.read(currentSessionIdProvider);
          if (currentSession != null) {
            debugPrint('   Session $currentSession closed (stays in storage)');
            ref.read(currentSessionIdProvider.notifier).state = null;
          }
          ref.read(workspaceProvider.notifier).switchToHeroMode();
          _transitionController.reverse();
        },
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): () {
          debugPrint('⬅️  Closing session (Ctrl+N pressed)');
          final currentSession = ref.read(currentSessionIdProvider);
          if (currentSession != null) {
            debugPrint('   Session $currentSession closed (stays in storage)');
            ref.read(currentSessionIdProvider.notifier).state = null;
          }
          ref.read(workspaceProvider.notifier).switchToHeroMode();
          _transitionController.reverse();
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child:
                isHeroMode
                    ? HeroSearchView(
                      key: const ValueKey('hero'),
                      onSearch: _handleSearch,
                    )
                    : FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildResearchMode(workspaceState),
                    ),
          ),
        ),
      ),
    );
  }

  Widget _buildResearchMode(WorkspaceState state) {
    return Row(
      key: const ValueKey('research'),
      children: [
        // Left pane - Search results (60%)
        Expanded(
          flex: 60,
          child: SearchResultsPane(
            results: state.searchResults,
            isLoading: state.isSearching,
            query: state.currentQuery,
            onAskAI: _handleAskAI,
          ),
        ),

        // Right pane - AI Chat (40%)
        const Expanded(flex: 40, child: AiChatPane()),
      ],
    );
  }
}
