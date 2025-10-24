// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_database.dart';

// ignore_for_file: type=lint
class $ConversationsTable extends Conversations
    with TableInfo<$ConversationsTable, Conversation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConversationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _queryMeta = const VerificationMeta('query');
  @override
  late final GeneratedColumn<String> query = GeneratedColumn<String>(
    'query',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastModifiedMeta = const VerificationMeta(
    'lastModified',
  );
  @override
  late final GeneratedColumn<DateTime> lastModified = GeneratedColumn<DateTime>(
    'last_modified',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _articleIdsMeta = const VerificationMeta(
    'articleIds',
  );
  @override
  late final GeneratedColumn<String> articleIds = GeneratedColumn<String>(
    'article_ids',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messageCountMeta = const VerificationMeta(
    'messageCount',
  );
  @override
  late final GeneratedColumn<int> messageCount = GeneratedColumn<int>(
    'message_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    query,
    createdAt,
    lastModified,
    articleIds,
    messageCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'conversations';
  @override
  VerificationContext validateIntegrity(
    Insertable<Conversation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('query')) {
      context.handle(
        _queryMeta,
        query.isAcceptableOrUnknown(data['query']!, _queryMeta),
      );
    } else if (isInserting) {
      context.missing(_queryMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_modified')) {
      context.handle(
        _lastModifiedMeta,
        lastModified.isAcceptableOrUnknown(
          data['last_modified']!,
          _lastModifiedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastModifiedMeta);
    }
    if (data.containsKey('article_ids')) {
      context.handle(
        _articleIdsMeta,
        articleIds.isAcceptableOrUnknown(data['article_ids']!, _articleIdsMeta),
      );
    } else if (isInserting) {
      context.missing(_articleIdsMeta);
    }
    if (data.containsKey('message_count')) {
      context.handle(
        _messageCountMeta,
        messageCount.isAcceptableOrUnknown(
          data['message_count']!,
          _messageCountMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Conversation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Conversation(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      query:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}query'],
          )!,
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
      lastModified:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}last_modified'],
          )!,
      articleIds:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}article_ids'],
          )!,
      messageCount:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}message_count'],
          )!,
    );
  }

  @override
  $ConversationsTable createAlias(String alias) {
    return $ConversationsTable(attachedDatabase, alias);
  }
}

class Conversation extends DataClass implements Insertable<Conversation> {
  final int id;
  final String query;
  final DateTime createdAt;
  final DateTime lastModified;
  final String articleIds;
  final int messageCount;
  const Conversation({
    required this.id,
    required this.query,
    required this.createdAt,
    required this.lastModified,
    required this.articleIds,
    required this.messageCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['query'] = Variable<String>(query);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['last_modified'] = Variable<DateTime>(lastModified);
    map['article_ids'] = Variable<String>(articleIds);
    map['message_count'] = Variable<int>(messageCount);
    return map;
  }

  ConversationsCompanion toCompanion(bool nullToAbsent) {
    return ConversationsCompanion(
      id: Value(id),
      query: Value(query),
      createdAt: Value(createdAt),
      lastModified: Value(lastModified),
      articleIds: Value(articleIds),
      messageCount: Value(messageCount),
    );
  }

  factory Conversation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Conversation(
      id: serializer.fromJson<int>(json['id']),
      query: serializer.fromJson<String>(json['query']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastModified: serializer.fromJson<DateTime>(json['lastModified']),
      articleIds: serializer.fromJson<String>(json['articleIds']),
      messageCount: serializer.fromJson<int>(json['messageCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'query': serializer.toJson<String>(query),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastModified': serializer.toJson<DateTime>(lastModified),
      'articleIds': serializer.toJson<String>(articleIds),
      'messageCount': serializer.toJson<int>(messageCount),
    };
  }

  Conversation copyWith({
    int? id,
    String? query,
    DateTime? createdAt,
    DateTime? lastModified,
    String? articleIds,
    int? messageCount,
  }) => Conversation(
    id: id ?? this.id,
    query: query ?? this.query,
    createdAt: createdAt ?? this.createdAt,
    lastModified: lastModified ?? this.lastModified,
    articleIds: articleIds ?? this.articleIds,
    messageCount: messageCount ?? this.messageCount,
  );
  Conversation copyWithCompanion(ConversationsCompanion data) {
    return Conversation(
      id: data.id.present ? data.id.value : this.id,
      query: data.query.present ? data.query.value : this.query,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastModified:
          data.lastModified.present
              ? data.lastModified.value
              : this.lastModified,
      articleIds:
          data.articleIds.present ? data.articleIds.value : this.articleIds,
      messageCount:
          data.messageCount.present
              ? data.messageCount.value
              : this.messageCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Conversation(')
          ..write('id: $id, ')
          ..write('query: $query, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastModified: $lastModified, ')
          ..write('articleIds: $articleIds, ')
          ..write('messageCount: $messageCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, query, createdAt, lastModified, articleIds, messageCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Conversation &&
          other.id == this.id &&
          other.query == this.query &&
          other.createdAt == this.createdAt &&
          other.lastModified == this.lastModified &&
          other.articleIds == this.articleIds &&
          other.messageCount == this.messageCount);
}

class ConversationsCompanion extends UpdateCompanion<Conversation> {
  final Value<int> id;
  final Value<String> query;
  final Value<DateTime> createdAt;
  final Value<DateTime> lastModified;
  final Value<String> articleIds;
  final Value<int> messageCount;
  const ConversationsCompanion({
    this.id = const Value.absent(),
    this.query = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.articleIds = const Value.absent(),
    this.messageCount = const Value.absent(),
  });
  ConversationsCompanion.insert({
    this.id = const Value.absent(),
    required String query,
    required DateTime createdAt,
    required DateTime lastModified,
    required String articleIds,
    this.messageCount = const Value.absent(),
  }) : query = Value(query),
       createdAt = Value(createdAt),
       lastModified = Value(lastModified),
       articleIds = Value(articleIds);
  static Insertable<Conversation> custom({
    Expression<int>? id,
    Expression<String>? query,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastModified,
    Expression<String>? articleIds,
    Expression<int>? messageCount,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (query != null) 'query': query,
      if (createdAt != null) 'created_at': createdAt,
      if (lastModified != null) 'last_modified': lastModified,
      if (articleIds != null) 'article_ids': articleIds,
      if (messageCount != null) 'message_count': messageCount,
    });
  }

  ConversationsCompanion copyWith({
    Value<int>? id,
    Value<String>? query,
    Value<DateTime>? createdAt,
    Value<DateTime>? lastModified,
    Value<String>? articleIds,
    Value<int>? messageCount,
  }) {
    return ConversationsCompanion(
      id: id ?? this.id,
      query: query ?? this.query,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      articleIds: articleIds ?? this.articleIds,
      messageCount: messageCount ?? this.messageCount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (query.present) {
      map['query'] = Variable<String>(query.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<DateTime>(lastModified.value);
    }
    if (articleIds.present) {
      map['article_ids'] = Variable<String>(articleIds.value);
    }
    if (messageCount.present) {
      map['message_count'] = Variable<int>(messageCount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConversationsCompanion(')
          ..write('id: $id, ')
          ..write('query: $query, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastModified: $lastModified, ')
          ..write('articleIds: $articleIds, ')
          ..write('messageCount: $messageCount')
          ..write(')'))
        .toString();
  }
}

class $ChatMessagesTable extends ChatMessages
    with TableInfo<$ChatMessagesTable, ChatMessage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChatMessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _conversationIdMeta = const VerificationMeta(
    'conversationId',
  );
  @override
  late final GeneratedColumn<int> conversationId = GeneratedColumn<int>(
    'conversation_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES conversations (id)',
    ),
  );
  static const VerificationMeta _messageMeta = const VerificationMeta(
    'message',
  );
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
    'message',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isUserMeta = const VerificationMeta('isUser');
  @override
  late final GeneratedColumn<bool> isUser = GeneratedColumn<bool>(
    'is_user',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_user" IN (0, 1))',
    ),
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _toolNameMeta = const VerificationMeta(
    'toolName',
  );
  @override
  late final GeneratedColumn<String> toolName = GeneratedColumn<String>(
    'tool_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _toolArgsMeta = const VerificationMeta(
    'toolArgs',
  );
  @override
  late final GeneratedColumn<String> toolArgs = GeneratedColumn<String>(
    'tool_args',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _toolResultMeta = const VerificationMeta(
    'toolResult',
  );
  @override
  late final GeneratedColumn<String> toolResult = GeneratedColumn<String>(
    'tool_result',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceServerIdMeta = const VerificationMeta(
    'sourceServerId',
  );
  @override
  late final GeneratedColumn<String> sourceServerId = GeneratedColumn<String>(
    'source_server_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceServerNameMeta = const VerificationMeta(
    'sourceServerName',
  );
  @override
  late final GeneratedColumn<String> sourceServerName = GeneratedColumn<String>(
    'source_server_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    conversationId,
    message,
    isUser,
    timestamp,
    toolName,
    toolArgs,
    toolResult,
    sourceServerId,
    sourceServerName,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chat_messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChatMessage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('conversation_id')) {
      context.handle(
        _conversationIdMeta,
        conversationId.isAcceptableOrUnknown(
          data['conversation_id']!,
          _conversationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_conversationIdMeta);
    }
    if (data.containsKey('message')) {
      context.handle(
        _messageMeta,
        message.isAcceptableOrUnknown(data['message']!, _messageMeta),
      );
    } else if (isInserting) {
      context.missing(_messageMeta);
    }
    if (data.containsKey('is_user')) {
      context.handle(
        _isUserMeta,
        isUser.isAcceptableOrUnknown(data['is_user']!, _isUserMeta),
      );
    } else if (isInserting) {
      context.missing(_isUserMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('tool_name')) {
      context.handle(
        _toolNameMeta,
        toolName.isAcceptableOrUnknown(data['tool_name']!, _toolNameMeta),
      );
    }
    if (data.containsKey('tool_args')) {
      context.handle(
        _toolArgsMeta,
        toolArgs.isAcceptableOrUnknown(data['tool_args']!, _toolArgsMeta),
      );
    }
    if (data.containsKey('tool_result')) {
      context.handle(
        _toolResultMeta,
        toolResult.isAcceptableOrUnknown(data['tool_result']!, _toolResultMeta),
      );
    }
    if (data.containsKey('source_server_id')) {
      context.handle(
        _sourceServerIdMeta,
        sourceServerId.isAcceptableOrUnknown(
          data['source_server_id']!,
          _sourceServerIdMeta,
        ),
      );
    }
    if (data.containsKey('source_server_name')) {
      context.handle(
        _sourceServerNameMeta,
        sourceServerName.isAcceptableOrUnknown(
          data['source_server_name']!,
          _sourceServerNameMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChatMessage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChatMessage(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      conversationId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}conversation_id'],
          )!,
      message:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}message'],
          )!,
      isUser:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_user'],
          )!,
      timestamp:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}timestamp'],
          )!,
      toolName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tool_name'],
      ),
      toolArgs: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tool_args'],
      ),
      toolResult: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tool_result'],
      ),
      sourceServerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_server_id'],
      ),
      sourceServerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_server_name'],
      ),
    );
  }

  @override
  $ChatMessagesTable createAlias(String alias) {
    return $ChatMessagesTable(attachedDatabase, alias);
  }
}

class ChatMessage extends DataClass implements Insertable<ChatMessage> {
  final int id;
  final int conversationId;
  final String message;
  final bool isUser;
  final DateTime timestamp;
  final String? toolName;
  final String? toolArgs;
  final String? toolResult;
  final String? sourceServerId;
  final String? sourceServerName;
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.message,
    required this.isUser,
    required this.timestamp,
    this.toolName,
    this.toolArgs,
    this.toolResult,
    this.sourceServerId,
    this.sourceServerName,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['conversation_id'] = Variable<int>(conversationId);
    map['message'] = Variable<String>(message);
    map['is_user'] = Variable<bool>(isUser);
    map['timestamp'] = Variable<DateTime>(timestamp);
    if (!nullToAbsent || toolName != null) {
      map['tool_name'] = Variable<String>(toolName);
    }
    if (!nullToAbsent || toolArgs != null) {
      map['tool_args'] = Variable<String>(toolArgs);
    }
    if (!nullToAbsent || toolResult != null) {
      map['tool_result'] = Variable<String>(toolResult);
    }
    if (!nullToAbsent || sourceServerId != null) {
      map['source_server_id'] = Variable<String>(sourceServerId);
    }
    if (!nullToAbsent || sourceServerName != null) {
      map['source_server_name'] = Variable<String>(sourceServerName);
    }
    return map;
  }

  ChatMessagesCompanion toCompanion(bool nullToAbsent) {
    return ChatMessagesCompanion(
      id: Value(id),
      conversationId: Value(conversationId),
      message: Value(message),
      isUser: Value(isUser),
      timestamp: Value(timestamp),
      toolName:
          toolName == null && nullToAbsent
              ? const Value.absent()
              : Value(toolName),
      toolArgs:
          toolArgs == null && nullToAbsent
              ? const Value.absent()
              : Value(toolArgs),
      toolResult:
          toolResult == null && nullToAbsent
              ? const Value.absent()
              : Value(toolResult),
      sourceServerId:
          sourceServerId == null && nullToAbsent
              ? const Value.absent()
              : Value(sourceServerId),
      sourceServerName:
          sourceServerName == null && nullToAbsent
              ? const Value.absent()
              : Value(sourceServerName),
    );
  }

  factory ChatMessage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChatMessage(
      id: serializer.fromJson<int>(json['id']),
      conversationId: serializer.fromJson<int>(json['conversationId']),
      message: serializer.fromJson<String>(json['message']),
      isUser: serializer.fromJson<bool>(json['isUser']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      toolName: serializer.fromJson<String?>(json['toolName']),
      toolArgs: serializer.fromJson<String?>(json['toolArgs']),
      toolResult: serializer.fromJson<String?>(json['toolResult']),
      sourceServerId: serializer.fromJson<String?>(json['sourceServerId']),
      sourceServerName: serializer.fromJson<String?>(json['sourceServerName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'conversationId': serializer.toJson<int>(conversationId),
      'message': serializer.toJson<String>(message),
      'isUser': serializer.toJson<bool>(isUser),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'toolName': serializer.toJson<String?>(toolName),
      'toolArgs': serializer.toJson<String?>(toolArgs),
      'toolResult': serializer.toJson<String?>(toolResult),
      'sourceServerId': serializer.toJson<String?>(sourceServerId),
      'sourceServerName': serializer.toJson<String?>(sourceServerName),
    };
  }

  ChatMessage copyWith({
    int? id,
    int? conversationId,
    String? message,
    bool? isUser,
    DateTime? timestamp,
    Value<String?> toolName = const Value.absent(),
    Value<String?> toolArgs = const Value.absent(),
    Value<String?> toolResult = const Value.absent(),
    Value<String?> sourceServerId = const Value.absent(),
    Value<String?> sourceServerName = const Value.absent(),
  }) => ChatMessage(
    id: id ?? this.id,
    conversationId: conversationId ?? this.conversationId,
    message: message ?? this.message,
    isUser: isUser ?? this.isUser,
    timestamp: timestamp ?? this.timestamp,
    toolName: toolName.present ? toolName.value : this.toolName,
    toolArgs: toolArgs.present ? toolArgs.value : this.toolArgs,
    toolResult: toolResult.present ? toolResult.value : this.toolResult,
    sourceServerId:
        sourceServerId.present ? sourceServerId.value : this.sourceServerId,
    sourceServerName:
        sourceServerName.present
            ? sourceServerName.value
            : this.sourceServerName,
  );
  ChatMessage copyWithCompanion(ChatMessagesCompanion data) {
    return ChatMessage(
      id: data.id.present ? data.id.value : this.id,
      conversationId:
          data.conversationId.present
              ? data.conversationId.value
              : this.conversationId,
      message: data.message.present ? data.message.value : this.message,
      isUser: data.isUser.present ? data.isUser.value : this.isUser,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      toolName: data.toolName.present ? data.toolName.value : this.toolName,
      toolArgs: data.toolArgs.present ? data.toolArgs.value : this.toolArgs,
      toolResult:
          data.toolResult.present ? data.toolResult.value : this.toolResult,
      sourceServerId:
          data.sourceServerId.present
              ? data.sourceServerId.value
              : this.sourceServerId,
      sourceServerName:
          data.sourceServerName.present
              ? data.sourceServerName.value
              : this.sourceServerName,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChatMessage(')
          ..write('id: $id, ')
          ..write('conversationId: $conversationId, ')
          ..write('message: $message, ')
          ..write('isUser: $isUser, ')
          ..write('timestamp: $timestamp, ')
          ..write('toolName: $toolName, ')
          ..write('toolArgs: $toolArgs, ')
          ..write('toolResult: $toolResult, ')
          ..write('sourceServerId: $sourceServerId, ')
          ..write('sourceServerName: $sourceServerName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    conversationId,
    message,
    isUser,
    timestamp,
    toolName,
    toolArgs,
    toolResult,
    sourceServerId,
    sourceServerName,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatMessage &&
          other.id == this.id &&
          other.conversationId == this.conversationId &&
          other.message == this.message &&
          other.isUser == this.isUser &&
          other.timestamp == this.timestamp &&
          other.toolName == this.toolName &&
          other.toolArgs == this.toolArgs &&
          other.toolResult == this.toolResult &&
          other.sourceServerId == this.sourceServerId &&
          other.sourceServerName == this.sourceServerName);
}

class ChatMessagesCompanion extends UpdateCompanion<ChatMessage> {
  final Value<int> id;
  final Value<int> conversationId;
  final Value<String> message;
  final Value<bool> isUser;
  final Value<DateTime> timestamp;
  final Value<String?> toolName;
  final Value<String?> toolArgs;
  final Value<String?> toolResult;
  final Value<String?> sourceServerId;
  final Value<String?> sourceServerName;
  const ChatMessagesCompanion({
    this.id = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.message = const Value.absent(),
    this.isUser = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.toolName = const Value.absent(),
    this.toolArgs = const Value.absent(),
    this.toolResult = const Value.absent(),
    this.sourceServerId = const Value.absent(),
    this.sourceServerName = const Value.absent(),
  });
  ChatMessagesCompanion.insert({
    this.id = const Value.absent(),
    required int conversationId,
    required String message,
    required bool isUser,
    required DateTime timestamp,
    this.toolName = const Value.absent(),
    this.toolArgs = const Value.absent(),
    this.toolResult = const Value.absent(),
    this.sourceServerId = const Value.absent(),
    this.sourceServerName = const Value.absent(),
  }) : conversationId = Value(conversationId),
       message = Value(message),
       isUser = Value(isUser),
       timestamp = Value(timestamp);
  static Insertable<ChatMessage> custom({
    Expression<int>? id,
    Expression<int>? conversationId,
    Expression<String>? message,
    Expression<bool>? isUser,
    Expression<DateTime>? timestamp,
    Expression<String>? toolName,
    Expression<String>? toolArgs,
    Expression<String>? toolResult,
    Expression<String>? sourceServerId,
    Expression<String>? sourceServerName,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (conversationId != null) 'conversation_id': conversationId,
      if (message != null) 'message': message,
      if (isUser != null) 'is_user': isUser,
      if (timestamp != null) 'timestamp': timestamp,
      if (toolName != null) 'tool_name': toolName,
      if (toolArgs != null) 'tool_args': toolArgs,
      if (toolResult != null) 'tool_result': toolResult,
      if (sourceServerId != null) 'source_server_id': sourceServerId,
      if (sourceServerName != null) 'source_server_name': sourceServerName,
    });
  }

  ChatMessagesCompanion copyWith({
    Value<int>? id,
    Value<int>? conversationId,
    Value<String>? message,
    Value<bool>? isUser,
    Value<DateTime>? timestamp,
    Value<String?>? toolName,
    Value<String?>? toolArgs,
    Value<String?>? toolResult,
    Value<String?>? sourceServerId,
    Value<String?>? sourceServerName,
  }) {
    return ChatMessagesCompanion(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      message: message ?? this.message,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      toolName: toolName ?? this.toolName,
      toolArgs: toolArgs ?? this.toolArgs,
      toolResult: toolResult ?? this.toolResult,
      sourceServerId: sourceServerId ?? this.sourceServerId,
      sourceServerName: sourceServerName ?? this.sourceServerName,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (conversationId.present) {
      map['conversation_id'] = Variable<int>(conversationId.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (isUser.present) {
      map['is_user'] = Variable<bool>(isUser.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (toolName.present) {
      map['tool_name'] = Variable<String>(toolName.value);
    }
    if (toolArgs.present) {
      map['tool_args'] = Variable<String>(toolArgs.value);
    }
    if (toolResult.present) {
      map['tool_result'] = Variable<String>(toolResult.value);
    }
    if (sourceServerId.present) {
      map['source_server_id'] = Variable<String>(sourceServerId.value);
    }
    if (sourceServerName.present) {
      map['source_server_name'] = Variable<String>(sourceServerName.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChatMessagesCompanion(')
          ..write('id: $id, ')
          ..write('conversationId: $conversationId, ')
          ..write('message: $message, ')
          ..write('isUser: $isUser, ')
          ..write('timestamp: $timestamp, ')
          ..write('toolName: $toolName, ')
          ..write('toolArgs: $toolArgs, ')
          ..write('toolResult: $toolResult, ')
          ..write('sourceServerId: $sourceServerId, ')
          ..write('sourceServerName: $sourceServerName')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ConversationsTable conversations = $ConversationsTable(this);
  late final $ChatMessagesTable chatMessages = $ChatMessagesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    conversations,
    chatMessages,
  ];
}

typedef $$ConversationsTableCreateCompanionBuilder =
    ConversationsCompanion Function({
      Value<int> id,
      required String query,
      required DateTime createdAt,
      required DateTime lastModified,
      required String articleIds,
      Value<int> messageCount,
    });
typedef $$ConversationsTableUpdateCompanionBuilder =
    ConversationsCompanion Function({
      Value<int> id,
      Value<String> query,
      Value<DateTime> createdAt,
      Value<DateTime> lastModified,
      Value<String> articleIds,
      Value<int> messageCount,
    });

final class $$ConversationsTableReferences
    extends BaseReferences<_$AppDatabase, $ConversationsTable, Conversation> {
  $$ConversationsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$ChatMessagesTable, List<ChatMessage>>
  _chatMessagesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.chatMessages,
    aliasName: $_aliasNameGenerator(
      db.conversations.id,
      db.chatMessages.conversationId,
    ),
  );

  $$ChatMessagesTableProcessedTableManager get chatMessagesRefs {
    final manager = $$ChatMessagesTableTableManager(
      $_db,
      $_db.chatMessages,
    ).filter((f) => f.conversationId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_chatMessagesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ConversationsTableFilterComposer
    extends Composer<_$AppDatabase, $ConversationsTable> {
  $$ConversationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get query => $composableBuilder(
    column: $table.query,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get articleIds => $composableBuilder(
    column: $table.articleIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get messageCount => $composableBuilder(
    column: $table.messageCount,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> chatMessagesRefs(
    Expression<bool> Function($$ChatMessagesTableFilterComposer f) f,
  ) {
    final $$ChatMessagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.chatMessages,
      getReferencedColumn: (t) => t.conversationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChatMessagesTableFilterComposer(
            $db: $db,
            $table: $db.chatMessages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ConversationsTableOrderingComposer
    extends Composer<_$AppDatabase, $ConversationsTable> {
  $$ConversationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get query => $composableBuilder(
    column: $table.query,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get articleIds => $composableBuilder(
    column: $table.articleIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get messageCount => $composableBuilder(
    column: $table.messageCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ConversationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConversationsTable> {
  $$ConversationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get query =>
      $composableBuilder(column: $table.query, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => column,
  );

  GeneratedColumn<String> get articleIds => $composableBuilder(
    column: $table.articleIds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get messageCount => $composableBuilder(
    column: $table.messageCount,
    builder: (column) => column,
  );

  Expression<T> chatMessagesRefs<T extends Object>(
    Expression<T> Function($$ChatMessagesTableAnnotationComposer a) f,
  ) {
    final $$ChatMessagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.chatMessages,
      getReferencedColumn: (t) => t.conversationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChatMessagesTableAnnotationComposer(
            $db: $db,
            $table: $db.chatMessages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ConversationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConversationsTable,
          Conversation,
          $$ConversationsTableFilterComposer,
          $$ConversationsTableOrderingComposer,
          $$ConversationsTableAnnotationComposer,
          $$ConversationsTableCreateCompanionBuilder,
          $$ConversationsTableUpdateCompanionBuilder,
          (Conversation, $$ConversationsTableReferences),
          Conversation,
          PrefetchHooks Function({bool chatMessagesRefs})
        > {
  $$ConversationsTableTableManager(_$AppDatabase db, $ConversationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$ConversationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () =>
                  $$ConversationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$ConversationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> query = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> lastModified = const Value.absent(),
                Value<String> articleIds = const Value.absent(),
                Value<int> messageCount = const Value.absent(),
              }) => ConversationsCompanion(
                id: id,
                query: query,
                createdAt: createdAt,
                lastModified: lastModified,
                articleIds: articleIds,
                messageCount: messageCount,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String query,
                required DateTime createdAt,
                required DateTime lastModified,
                required String articleIds,
                Value<int> messageCount = const Value.absent(),
              }) => ConversationsCompanion.insert(
                id: id,
                query: query,
                createdAt: createdAt,
                lastModified: lastModified,
                articleIds: articleIds,
                messageCount: messageCount,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$ConversationsTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({chatMessagesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (chatMessagesRefs) db.chatMessages],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (chatMessagesRefs)
                    await $_getPrefetchedData<
                      Conversation,
                      $ConversationsTable,
                      ChatMessage
                    >(
                      currentTable: table,
                      referencedTable: $$ConversationsTableReferences
                          ._chatMessagesRefsTable(db),
                      managerFromTypedResult:
                          (p0) =>
                              $$ConversationsTableReferences(
                                db,
                                table,
                                p0,
                              ).chatMessagesRefs,
                      referencedItemsForCurrentItem:
                          (item, referencedItems) => referencedItems.where(
                            (e) => e.conversationId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ConversationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConversationsTable,
      Conversation,
      $$ConversationsTableFilterComposer,
      $$ConversationsTableOrderingComposer,
      $$ConversationsTableAnnotationComposer,
      $$ConversationsTableCreateCompanionBuilder,
      $$ConversationsTableUpdateCompanionBuilder,
      (Conversation, $$ConversationsTableReferences),
      Conversation,
      PrefetchHooks Function({bool chatMessagesRefs})
    >;
typedef $$ChatMessagesTableCreateCompanionBuilder =
    ChatMessagesCompanion Function({
      Value<int> id,
      required int conversationId,
      required String message,
      required bool isUser,
      required DateTime timestamp,
      Value<String?> toolName,
      Value<String?> toolArgs,
      Value<String?> toolResult,
      Value<String?> sourceServerId,
      Value<String?> sourceServerName,
    });
typedef $$ChatMessagesTableUpdateCompanionBuilder =
    ChatMessagesCompanion Function({
      Value<int> id,
      Value<int> conversationId,
      Value<String> message,
      Value<bool> isUser,
      Value<DateTime> timestamp,
      Value<String?> toolName,
      Value<String?> toolArgs,
      Value<String?> toolResult,
      Value<String?> sourceServerId,
      Value<String?> sourceServerName,
    });

final class $$ChatMessagesTableReferences
    extends BaseReferences<_$AppDatabase, $ChatMessagesTable, ChatMessage> {
  $$ChatMessagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ConversationsTable _conversationIdTable(_$AppDatabase db) =>
      db.conversations.createAlias(
        $_aliasNameGenerator(
          db.chatMessages.conversationId,
          db.conversations.id,
        ),
      );

  $$ConversationsTableProcessedTableManager get conversationId {
    final $_column = $_itemColumn<int>('conversation_id')!;

    final manager = $$ConversationsTableTableManager(
      $_db,
      $_db.conversations,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_conversationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ChatMessagesTableFilterComposer
    extends Composer<_$AppDatabase, $ChatMessagesTable> {
  $$ChatMessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isUser => $composableBuilder(
    column: $table.isUser,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toolName => $composableBuilder(
    column: $table.toolName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toolArgs => $composableBuilder(
    column: $table.toolArgs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toolResult => $composableBuilder(
    column: $table.toolResult,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceServerId => $composableBuilder(
    column: $table.sourceServerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceServerName => $composableBuilder(
    column: $table.sourceServerName,
    builder: (column) => ColumnFilters(column),
  );

  $$ConversationsTableFilterComposer get conversationId {
    final $$ConversationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.conversationId,
      referencedTable: $db.conversations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConversationsTableFilterComposer(
            $db: $db,
            $table: $db.conversations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChatMessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $ChatMessagesTable> {
  $$ChatMessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isUser => $composableBuilder(
    column: $table.isUser,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toolName => $composableBuilder(
    column: $table.toolName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toolArgs => $composableBuilder(
    column: $table.toolArgs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toolResult => $composableBuilder(
    column: $table.toolResult,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceServerId => $composableBuilder(
    column: $table.sourceServerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceServerName => $composableBuilder(
    column: $table.sourceServerName,
    builder: (column) => ColumnOrderings(column),
  );

  $$ConversationsTableOrderingComposer get conversationId {
    final $$ConversationsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.conversationId,
      referencedTable: $db.conversations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConversationsTableOrderingComposer(
            $db: $db,
            $table: $db.conversations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChatMessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChatMessagesTable> {
  $$ChatMessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<bool> get isUser =>
      $composableBuilder(column: $table.isUser, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get toolName =>
      $composableBuilder(column: $table.toolName, builder: (column) => column);

  GeneratedColumn<String> get toolArgs =>
      $composableBuilder(column: $table.toolArgs, builder: (column) => column);

  GeneratedColumn<String> get toolResult => $composableBuilder(
    column: $table.toolResult,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceServerId => $composableBuilder(
    column: $table.sourceServerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceServerName => $composableBuilder(
    column: $table.sourceServerName,
    builder: (column) => column,
  );

  $$ConversationsTableAnnotationComposer get conversationId {
    final $$ConversationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.conversationId,
      referencedTable: $db.conversations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConversationsTableAnnotationComposer(
            $db: $db,
            $table: $db.conversations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChatMessagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChatMessagesTable,
          ChatMessage,
          $$ChatMessagesTableFilterComposer,
          $$ChatMessagesTableOrderingComposer,
          $$ChatMessagesTableAnnotationComposer,
          $$ChatMessagesTableCreateCompanionBuilder,
          $$ChatMessagesTableUpdateCompanionBuilder,
          (ChatMessage, $$ChatMessagesTableReferences),
          ChatMessage,
          PrefetchHooks Function({bool conversationId})
        > {
  $$ChatMessagesTableTableManager(_$AppDatabase db, $ChatMessagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$ChatMessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$ChatMessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () =>
                  $$ChatMessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> conversationId = const Value.absent(),
                Value<String> message = const Value.absent(),
                Value<bool> isUser = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<String?> toolName = const Value.absent(),
                Value<String?> toolArgs = const Value.absent(),
                Value<String?> toolResult = const Value.absent(),
                Value<String?> sourceServerId = const Value.absent(),
                Value<String?> sourceServerName = const Value.absent(),
              }) => ChatMessagesCompanion(
                id: id,
                conversationId: conversationId,
                message: message,
                isUser: isUser,
                timestamp: timestamp,
                toolName: toolName,
                toolArgs: toolArgs,
                toolResult: toolResult,
                sourceServerId: sourceServerId,
                sourceServerName: sourceServerName,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int conversationId,
                required String message,
                required bool isUser,
                required DateTime timestamp,
                Value<String?> toolName = const Value.absent(),
                Value<String?> toolArgs = const Value.absent(),
                Value<String?> toolResult = const Value.absent(),
                Value<String?> sourceServerId = const Value.absent(),
                Value<String?> sourceServerName = const Value.absent(),
              }) => ChatMessagesCompanion.insert(
                id: id,
                conversationId: conversationId,
                message: message,
                isUser: isUser,
                timestamp: timestamp,
                toolName: toolName,
                toolArgs: toolArgs,
                toolResult: toolResult,
                sourceServerId: sourceServerId,
                sourceServerName: sourceServerName,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$ChatMessagesTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({conversationId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                T extends TableManagerState<
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic
                >
              >(state) {
                if (conversationId) {
                  state =
                      state.withJoin(
                            currentTable: table,
                            currentColumn: table.conversationId,
                            referencedTable: $$ChatMessagesTableReferences
                                ._conversationIdTable(db),
                            referencedColumn:
                                $$ChatMessagesTableReferences
                                    ._conversationIdTable(db)
                                    .id,
                          )
                          as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ChatMessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChatMessagesTable,
      ChatMessage,
      $$ChatMessagesTableFilterComposer,
      $$ChatMessagesTableOrderingComposer,
      $$ChatMessagesTableAnnotationComposer,
      $$ChatMessagesTableCreateCompanionBuilder,
      $$ChatMessagesTableUpdateCompanionBuilder,
      (ChatMessage, $$ChatMessagesTableReferences),
      ChatMessage,
      PrefetchHooks Function({bool conversationId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ConversationsTableTableManager get conversations =>
      $$ConversationsTableTableManager(_db, _db.conversations);
  $$ChatMessagesTableTableManager get chatMessages =>
      $$ChatMessagesTableTableManager(_db, _db.chatMessages);
}
