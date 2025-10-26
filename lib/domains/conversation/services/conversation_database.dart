import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import '../models/conversation_models.dart';

part 'conversation_database.g.dart';

/// Service for managing conversation persistence with Drift
@DriftDatabase(tables: [ChatMessages, Conversations])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'medicortex_conversations',
      web: DriftWebOptions(
        // GitHub Pages serves WASM with correct MIME type (application/wasm)
        // Appwrite Sites doesn't support custom headers, so we host WASM externally
        sqlite3Wasm: Uri.parse('https://flutterfanatic.github.io/medicortex-wasm-files/sqlite3.wasm'),
        driftWorker: Uri.parse('https://flutterfanatic.github.io/medicortex-wasm-files/drift_worker.js'),
      ),
    );
  }

  @override
  int get schemaVersion => 1;

  /// Create a new conversation
  Future<int> createConversation({
    required String query,
    required List<String> articleIds,
  }) async {
    return await into(conversations).insert(
      ConversationsCompanion.insert(
        query: query,
        createdAt: DateTime.now(),
        lastModified: DateTime.now(),
        articleIds: jsonEncode(articleIds),
        messageCount: const Value(0),
      ),
    );
  }

  /// Add a message to a conversation
  Future<void> addMessage({
    required int conversationId,
    required String text,
    required bool isUser,
    String? toolName,
    String? toolArgs,
    String? toolResult,
    String? sourceServerId,
    String? sourceServerName,
  }) async {
    await transaction(() async {
      // Add the message
      await into(chatMessages).insert(
        ChatMessagesCompanion.insert(
          conversationId: conversationId,
          message: text,
          isUser: isUser,
          timestamp: DateTime.now(),
          toolName: Value(toolName),
          toolArgs: Value(toolArgs),
          toolResult: Value(toolResult),
          sourceServerId: Value(sourceServerId),
          sourceServerName: Value(sourceServerName),
        ),
      );

      // Update conversation's lastModified and messageCount
      final conversation = await (select(conversations)
            ..where((tbl) => tbl.id.equals(conversationId)))
          .getSingleOrNull();

      if (conversation != null) {
        await (update(conversations)
              ..where((tbl) => tbl.id.equals(conversationId)))
            .write(
          ConversationsCompanion(
            lastModified: Value(DateTime.now()),
            messageCount: Value(conversation.messageCount + 1),
          ),
        );
      }
    });
  }

  /// Get a conversation by ID
  Future<Conversation?> getConversation(int id) async {
    return await (select(conversations)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  /// Get all messages for a conversation
  Future<List<ChatMessage>> getMessages(int conversationId) async {
    return await (select(chatMessages)
          ..where((tbl) => tbl.conversationId.equals(conversationId))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.timestamp)]))
        .get();
  }

  /// Get all conversations, sorted by last modified (most recent first)
  Future<List<Conversation>> getAllConversations({int limit = 50}) async {
    return await (select(conversations)
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.lastModified)])
          ..limit(limit))
        .get();
  }

  /// Search conversations by query
  Future<List<Conversation>> searchConversations(String searchTerm) async {
    return await (select(conversations)
          ..where((tbl) => tbl.query.contains(searchTerm))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.lastModified)]))
        .get();
  }

  /// Delete a message by conversationId and timestamp
  Future<void> deleteMessage(int conversationId, int timestamp) async {
    await transaction(() async {
      // Delete the message
      await (delete(chatMessages)
            ..where((tbl) =>
                tbl.conversationId.equals(conversationId) &
                tbl.timestamp.equals(DateTime.fromMillisecondsSinceEpoch(timestamp))))
          .go();

      // Update conversation's lastModified and messageCount
      final conversation = await (select(conversations)
            ..where((tbl) => tbl.id.equals(conversationId)))
          .getSingleOrNull();

      if (conversation != null && conversation.messageCount > 0) {
        await (update(conversations)
              ..where((tbl) => tbl.id.equals(conversationId)))
            .write(
          ConversationsCompanion(
            lastModified: Value(DateTime.now()),
            messageCount: Value(conversation.messageCount - 1),
          ),
        );
      }
    });
  }

  /// Delete a conversation and all its messages
  Future<void> deleteConversation(int id) async {
    await transaction(() async {
      // Delete all messages
      await (delete(chatMessages)
            ..where((tbl) => tbl.conversationId.equals(id)))
          .go();

      // Delete the conversation
      await (delete(conversations)..where((tbl) => tbl.id.equals(id))).go();
    });
  }

  /// Clear all conversations and messages
  Future<void> clearAll() async {
    await transaction(() async {
      await delete(chatMessages).go();
      await delete(conversations).go();
    });
  }

  /// Get conversation count
  Future<int> getConversationCount() async {
    final countQuery = selectOnly(conversations)..addColumns([conversations.id.count()]);
    final result = await countQuery.getSingle();
    return result.read(conversations.id.count()) ?? 0;
  }

  /// Get total message count across all conversations
  Future<int> getTotalMessageCount() async {
    final countQuery = selectOnly(chatMessages)..addColumns([chatMessages.id.count()]);
    final result = await countQuery.getSingle();
    return result.read(chatMessages.id.count()) ?? 0;
  }
}

/// Global database instance
class ConversationDatabase {
  static AppDatabase? _database;

  /// Initialize the database
  static Future<AppDatabase> initialize() async {
    _database ??= AppDatabase();
    return _database!;
  }

  /// Get the database instance
  static AppDatabase get instance {
    if (_database == null) {
      throw Exception('Database not initialized. Call initialize() first.');
    }
    return _database!;
  }

  /// Close the database
  static Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  // Wrapper methods for backwards compatibility
  static Future<int> createConversation({
    required String query,
    required List<String> articleIds,
  }) async {
    return await instance.createConversation(
      query: query,
      articleIds: articleIds,
    );
  }

  static Future<void> addMessage({
    required int conversationId,
    required String text,
    required bool isUser,
    String? toolName,
    String? toolArgs,
    String? toolResult,
    String? sourceServerId,
    String? sourceServerName,
  }) async {
    return await instance.addMessage(
      conversationId: conversationId,
      text: text,
      isUser: isUser,
      toolName: toolName,
      toolArgs: toolArgs,
      toolResult: toolResult,
      sourceServerId: sourceServerId,
      sourceServerName: sourceServerName,
    );
  }

  static Future<Conversation?> getConversation(int id) async {
    return await instance.getConversation(id);
  }

  static Future<List<ChatMessage>> getMessages(int conversationId) async {
    return await instance.getMessages(conversationId);
  }

  static Future<List<Conversation>> getAllConversations({int limit = 50}) async {
    return await instance.getAllConversations(limit: limit);
  }

  static Future<List<Conversation>> searchConversations(String searchTerm) async {
    return await instance.searchConversations(searchTerm);
  }

  static Future<void> deleteMessage(int conversationId, int timestamp) async {
    return await instance.deleteMessage(conversationId, timestamp);
  }

  static Future<void> deleteConversation(int id) async {
    return await instance.deleteConversation(id);
  }

  static Future<void> clearAll() async {
    return await instance.clearAll();
  }

  static Future<int> getConversationCount() async {
    return await instance.getConversationCount();
  }

  static Future<int> getTotalMessageCount() async {
    return await instance.getTotalMessageCount();
  }
}
