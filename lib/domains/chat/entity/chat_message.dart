import 'package:flutter/foundation.dart';

/// Represents a single message in the chat interface.
@immutable
class ChatMessage {
  final String text;
  final bool isUser;
  final String? toolName;
  final String? toolArgs; // Stored as JSON string for simplicity
  final String? toolResult; // Store the primary text result for display
  final String? sourceServerId;
  final String? sourceServerName;
  final int timestamp; // Milliseconds since epoch

  const ChatMessage({
    required this.text,
    required this.isUser,
    this.toolName,
    this.toolArgs,
    this.toolResult,
    this.sourceServerId,
    this.sourceServerName,
    int? timestamp,
  }) : timestamp = timestamp ?? 0;

  ChatMessage copyWith({
    String? text,
    bool? isUser,
    String? toolName,
    String? toolArgs,
    String? toolResult,
    String? sourceServerId,
    String? sourceServerName,
    int? timestamp,
    bool clearToolInfo = false,
  }) {
    return ChatMessage(
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      toolName: clearToolInfo ? null : toolName ?? this.toolName,
      toolArgs: clearToolInfo ? null : toolArgs ?? this.toolArgs,
      toolResult: clearToolInfo ? null : toolResult ?? this.toolResult,
      sourceServerId:
          clearToolInfo ? null : sourceServerId ?? this.sourceServerId,
      sourceServerName:
          clearToolInfo ? null : sourceServerName ?? this.sourceServerName,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessage &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          isUser == other.isUser &&
          toolName == other.toolName &&
          toolArgs == other.toolArgs &&
          toolResult == other.toolResult &&
          sourceServerId == other.sourceServerId &&
          sourceServerName == other.sourceServerName &&
          timestamp == other.timestamp;

  @override
  int get hashCode =>
      text.hashCode ^
      isUser.hashCode ^
      toolName.hashCode ^
      toolArgs.hashCode ^
      toolResult.hashCode ^
      sourceServerId.hashCode ^
      sourceServerName.hashCode ^
      timestamp.hashCode;
}
