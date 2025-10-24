import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domains/chat/entity/chat_message.dart' as entity;
import '../../domains/conversation/services/conversation_database.dart';
import '../../domains/search/domain/entities/search_result.dart';

/// Provider for the current active session ID
final currentSessionIdProvider = StateProvider<int?>((ref) => null);

/// Provider to track if we're currently restoring a conversation
final isRestoringConversationProvider = StateProvider<bool>((ref) => false);

/// State class for conversation management
class ConversationState {
  final Map<int, Conversation> conversations;
  final Map<int, List<ChatMessage>> messageCache;
  final bool isLoading;

  const ConversationState({
    this.conversations = const {},
    this.messageCache = const {},
    this.isLoading = false,
  });

  ConversationState copyWith({
    Map<int, Conversation>? conversations,
    Map<int, List<ChatMessage>>? messageCache,
    bool? isLoading,
  }) {
    return ConversationState(
      conversations: conversations ?? this.conversations,
      messageCache: messageCache ?? this.messageCache,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Notifier for managing conversations with Drift
class ConversationNotifier extends StateNotifier<ConversationState> {
  ConversationNotifier() : super(const ConversationState()) {
    _loadConversations();
  }

  /// Load all conversations from database
  Future<void> _loadConversations() async {
    try {
      state = state.copyWith(isLoading: true);

      final conversations = await ConversationDatabase.getAllConversations();
      final conversationMap = <int, Conversation>{};

      for (final conv in conversations) {
        conversationMap[conv.id] = conv;
      }

      state = state.copyWith(
        conversations: conversationMap,
        isLoading: false,
      );

      debugPrint('📚 Loaded ${conversations.length} conversations from Drift');
    } catch (e) {
      debugPrint('❌ Error loading conversations: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  /// Create a new conversation session
  Future<int> createSession(String query, List<SearchResult> articles) async {
    try {
      final articleIds = articles.map((a) => a.id).toList();

      final conversationId = await ConversationDatabase.createConversation(
        query: query,
        articleIds: articleIds,
      );

      debugPrint('✨ Created conversation in Drift: ID=$conversationId');

      // Reload to update state
      await _loadConversations();

      return conversationId;
    } catch (e) {
      debugPrint('❌ Error creating conversation: $e');
      rethrow;
    }
  }

  /// Add a message to a conversation
  Future<void> addMessage(int conversationId, entity.ChatMessage message) async {
    try {
      await ConversationDatabase.addMessage(
        conversationId: conversationId,
        text: message.text,
        isUser: message.isUser,
        toolName: message.toolName,
        toolArgs: message.toolArgs,
        toolResult: message.toolResult,
        sourceServerId: message.sourceServerId,
        sourceServerName: message.sourceServerName,
      );

      // Update cache
      final messages = await ConversationDatabase.getMessages(conversationId);
      final newCache = Map<int, List<ChatMessage>>.from(state.messageCache);
      newCache[conversationId] = messages;

      state = state.copyWith(messageCache: newCache);

      // Reload conversations to update counts
      await _loadConversations();
    } catch (e) {
      debugPrint('❌ Error adding message: $e');
    }
  }

  /// Get messages for a conversation (with caching)
  Future<List<entity.ChatMessage>> getMessages(int conversationId) async {
    try {
      // Check cache first
      if (state.messageCache.containsKey(conversationId)) {
        return _convertMessages(state.messageCache[conversationId]!);
      }

      // Load from database
      final messages = await ConversationDatabase.getMessages(conversationId);

      // Update cache
      final newCache = Map<int, List<ChatMessage>>.from(state.messageCache);
      newCache[conversationId] = messages;
      state = state.copyWith(messageCache: newCache);

      return _convertMessages(messages);
    } catch (e) {
      debugPrint('❌ Error getting messages: $e');
      return [];
    }
  }

  /// Convert Drift models to ChatMessage entities
  List<entity.ChatMessage> _convertMessages(List<ChatMessage> models) {
    return models.map((m) => entity.ChatMessage(
      text: m.message,
      isUser: m.isUser,
      toolName: m.toolName,
      toolArgs: m.toolArgs,
      toolResult: m.toolResult,
      sourceServerId: m.sourceServerId,
      sourceServerName: m.sourceServerName,
      timestamp: m.timestamp.millisecondsSinceEpoch,
    )).toList();
  }

  /// Get a conversation by ID
  Conversation? getConversation(int id) {
    return state.conversations[id];
  }

  /// Get article IDs for a conversation (parsed from JSON)
  List<String> getArticleIds(int id) {
    final conversation = getConversation(id);
    if (conversation == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(conversation.articleIds);
      return decoded.cast<String>();
    } catch (e) {
      debugPrint('❌ Error parsing article IDs: $e');
      return [];
    }
  }

  /// Delete a message from a conversation by timestamp
  Future<void> deleteMessage(int conversationId, int timestamp) async {
    try {
      await ConversationDatabase.deleteMessage(conversationId, timestamp);

      // Update cache
      final messages = await ConversationDatabase.getMessages(conversationId);
      final newCache = Map<int, List<ChatMessage>>.from(state.messageCache);
      newCache[conversationId] = messages;

      state = state.copyWith(messageCache: newCache);

      // Reload conversations to update counts
      await _loadConversations();

      debugPrint('🗑️  Deleted message with timestamp $timestamp from conversation $conversationId');
    } catch (e) {
      debugPrint('❌ Error deleting message: $e');
    }
  }

  /// Delete a conversation
  Future<void> deleteConversation(int id) async {
    try {
      await ConversationDatabase.deleteConversation(id);

      // Remove from cache
      final newConversations = Map<int, Conversation>.from(state.conversations);
      newConversations.remove(id);

      final newCache = Map<int, List<ChatMessage>>.from(state.messageCache);
      newCache.remove(id);

      state = state.copyWith(
        conversations: newConversations,
        messageCache: newCache,
      );

      debugPrint('🗑️  Deleted conversation: $id');
    } catch (e) {
      debugPrint('❌ Error deleting conversation: $e');
    }
  }

  /// Clear all conversations
  Future<void> clearAll() async {
    try {
      await ConversationDatabase.clearAll();
      state = const ConversationState();
      debugPrint('🗑️  Cleared all conversations');
    } catch (e) {
      debugPrint('❌ Error clearing conversations: $e');
    }
  }

  /// Refresh conversations from database
  Future<void> refresh() async {
    await _loadConversations();
  }
}

/// Provider for conversation management
final conversationIsarProvider = StateNotifierProvider<ConversationNotifier, ConversationState>((ref) {
  return ConversationNotifier();
});
