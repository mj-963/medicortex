import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:medicortex/domains/ai/entity/ai_entities.dart';
import 'package:medicortex/domains/chat/entity/chat_message.dart';

@immutable
class ChatState {
  final List<ChatMessage> displayMessages;
  final List<AiContent> chatHistory;
  final bool isLoading;
  final bool isApiKeySet;
  final String loadingStatus; // Status message shown in loading indicator

  const ChatState({
    this.displayMessages = const [],
    this.chatHistory = const [],
    this.isLoading = false,
    this.isApiKeySet = false,
    this.loadingStatus = 'AI is thinking...',
  });

  ChatState copyWith({
    List<ChatMessage>? displayMessages,
    List<AiContent>? chatHistory,
    bool? isLoading,
    bool? isApiKeySet,
    String? loadingStatus,
  }) {
    return ChatState(
      displayMessages: displayMessages ?? this.displayMessages,
      chatHistory: chatHistory ?? this.chatHistory,
      isLoading: isLoading ?? this.isLoading,
      isApiKeySet: isApiKeySet ?? this.isApiKeySet,
      loadingStatus: loadingStatus ?? this.loadingStatus,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatState &&
          runtimeType == other.runtimeType &&
          const ListEquality().equals(displayMessages, other.displayMessages) &&
          const ListEquality().equals(chatHistory, other.chatHistory) &&
          isLoading == other.isLoading &&
          isApiKeySet == other.isApiKeySet &&
          loadingStatus == other.loadingStatus;

  @override
  int get hashCode =>
      const ListEquality().hash(displayMessages) ^
      const ListEquality().hash(chatHistory) ^
      isLoading.hashCode ^
      isApiKeySet.hashCode ^
      loadingStatus.hashCode;
}
