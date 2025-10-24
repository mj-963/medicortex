import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domains/chat/entity/chat_message.dart';
import '../../domains/search/domain/entities/search_result.dart';
import '../../providers/settings_providers.dart';

/// Represents a complete conversation session
class ConversationSession {
  final String id; // Unique ID for this conversation
  final String query; // The search query
  final DateTime timestamp;
  final List<ChatMessage> messages;
  final List<String> articleIds; // PMIDs of articles in this session

  ConversationSession({
    required this.id,
    required this.query,
    required this.timestamp,
    required this.messages,
    required this.articleIds,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'query': query,
    'timestamp': timestamp.toIso8601String(),
    'messages': messages.map((m) => _messageToJson(m)).toList(),
    'articleIds': articleIds,
  };

  factory ConversationSession.fromJson(Map<String, dynamic> json) {
    return ConversationSession(
      id: json['id'] as String,
      query: json['query'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      messages:
          (json['messages'] as List)
              .map((m) => _messageFromJson(m as Map<String, dynamic>))
              .toList(),
      articleIds: (json['articleIds'] as List).cast<String>(),
    );
  }

  static Map<String, dynamic> _messageToJson(ChatMessage message) {
    return {
      'text': message.text,
      'isUser': message.isUser,
      'toolName': message.toolName,
      'toolArgs': message.toolArgs,
      'toolResult': message.toolResult,
    };
  }

  static ChatMessage _messageFromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'] as String,
      isUser: json['isUser'] as bool,
      timestamp: json['timestamp'] as int,
      toolName: json['toolName'] as String?,
      toolArgs: json['toolArgs'] as String?,
      toolResult: json['toolResult'] as String?,
    );
  }

  ConversationSession copyWith({
    String? id,
    String? query,
    DateTime? timestamp,
    List<ChatMessage>? messages,
    List<String>? articleIds,
  }) {
    return ConversationSession(
      id: id ?? this.id,
      query: query ?? this.query,
      timestamp: timestamp ?? this.timestamp,
      messages: messages ?? this.messages,
      articleIds: articleIds ?? this.articleIds,
    );
  }
}

class ConversationNotifier
    extends StateNotifier<Map<String, ConversationSession>> {
  final SharedPreferences _prefs;
  static const String _key = 'conversation_sessions';
  static const int _maxSessions = 50;

  ConversationNotifier(this._prefs) : super({}) {
    _loadConversations();
  }

  void _loadConversations() {
    try {
      final jsonStr = _prefs.getString(_key);
      if (jsonStr == null) {
        state = {};
        return;
      }

      final Map<String, dynamic> jsonMap = json.decode(jsonStr);
      final conversations = <String, ConversationSession>{};

      jsonMap.forEach((key, value) {
        try {
          conversations[key] = ConversationSession.fromJson(value);
        } catch (e) {
          // Skip invalid entries
        }
      });

      state = conversations;
    } catch (e) {
      state = {};
    }
  }

  Future<void> _saveConversations() async {
    try {
      final jsonMap = state.map(
        (key, session) => MapEntry(key, session.toJson()),
      );
      await _prefs.setString(_key, json.encode(jsonMap));
    } catch (e) {
      // Ignore save errors
    }
  }

  /// Create a new conversation session
  String createSession(String query, List<SearchResult> articles) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final session = ConversationSession(
      id: id,
      query: query,
      timestamp: DateTime.now(),
      messages: [],
      articleIds: articles.map((a) => a.id).toList(),
    );

    final updated = Map<String, ConversationSession>.from(state);
    updated[id] = session;

    // Keep only the last N sessions
    if (updated.length > _maxSessions) {
      final sorted =
          updated.entries.toList()
            ..sort((a, b) => b.value.timestamp.compareTo(a.value.timestamp));
      state = Map.fromEntries(sorted.take(_maxSessions));
    } else {
      state = updated;
    }

    _saveConversations();
    return id;
  }

  /// Add a message to a conversation
  Future<void> addMessage(String sessionId, ChatMessage message) async {
    final session = state[sessionId];
    if (session == null) return;

    final updatedMessages = [...session.messages, message];
    final updatedSession = session.copyWith(messages: updatedMessages);

    state = {...state, sessionId: updatedSession};

    await _saveConversations();
  }

  /// Get a conversation by ID
  ConversationSession? getSession(String sessionId) {
    return state[sessionId];
  }

  /// Get conversation by query (for resuming from history)
  ConversationSession? getSessionByQuery(String query) {
    // Find the most recent session with this query
    final sessions = state.values.where((s) => s.query == query).toList();
    if (sessions.isEmpty) return null;

    sessions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sessions.first;
  }

  /// Delete a conversation
  Future<void> deleteSession(String sessionId) async {
    final updated = Map<String, ConversationSession>.from(state);
    updated.remove(sessionId);
    state = updated;
    await _saveConversations();
  }

  /// Clear all conversations
  Future<void> clearAll() async {
    state = {};
    await _prefs.remove(_key);
  }
}

final conversationProvider = StateNotifierProvider<
  ConversationNotifier,
  Map<String, ConversationSession>
>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ConversationNotifier(prefs);
});

/// Provider for the current active session ID
final currentSessionIdProvider = StateProvider<String?>((ref) => null);
