import 'package:drift/drift.dart';

/// Table for storing chat messages
class ChatMessages extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get conversationId => integer().references(Conversations, #id)();
  TextColumn get message => text()();
  BoolColumn get isUser => boolean()();
  DateTimeColumn get timestamp => dateTime()();

  // Optional tool-related fields
  TextColumn get toolName => text().nullable()();
  TextColumn get toolArgs => text().nullable()();
  TextColumn get toolResult => text().nullable()();
  TextColumn get sourceServerId => text().nullable()();
  TextColumn get sourceServerName => text().nullable()();
}

/// Table for storing conversations/research sessions
class Conversations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get query => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastModified => dateTime()();

  // Store article IDs as JSON string
  TextColumn get articleIds => text()();

  // Number of messages (for quick reference)
  IntColumn get messageCount => integer().withDefault(const Constant(0))();
}
