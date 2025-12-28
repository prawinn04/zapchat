import 'package:hive/hive.dart';
import 'chat_message.dart';

part 'chat_session.g.dart';

@HiveType(typeId: 2)
class ChatSession extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final DateTime createdAt;

  @HiveField(3)
  final DateTime lastMessageAt;

  @HiveField(4)
  final List<ChatMessage> messages;

  @HiveField(5)
  final bool isActive;

  ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.lastMessageAt,
    required this.messages,
    this.isActive = false,
  });

  ChatSession copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? lastMessageAt,
    List<ChatMessage>? messages,
    bool? isActive,
  }) {
    return ChatSession(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      messages: messages ?? this.messages,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Generate a title from the first user message
  String generateTitle() {
    final firstUserMessage = messages
        .where((msg) => msg.isUser)
        .firstOrNull;
    
    if (firstUserMessage != null) {
      final content = firstUserMessage.content.trim();
      if (content.length > 30) {
        return '${content.substring(0, 30)}...';
      }
      return content;
    }
    
    return 'New Chat';
  }

  /// Check if conversation has reached the limit (e.g., 50 messages)
  bool hasReachedLimit({int limit = 50}) {
    return messages.length >= limit;
  }
}