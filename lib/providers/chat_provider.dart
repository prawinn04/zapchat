import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/chat_message.dart';
import '../services/deepseek_service.dart';
import 'settings_provider.dart';

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;
  final bool isTyping;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.isTyping = false,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
    bool? isTyping,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isTyping: isTyping ?? this.isTyping,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  static const String _boxName = 'chat_messages';
  late Box<ChatMessage> _box;
  final DeepSeekService _deepSeekService;
  final Ref _ref;
  StreamSubscription<String>? _streamSubscription;

  ChatNotifier(this._ref) 
      : _deepSeekService = DeepSeekService(),
        super(const ChatState()) {
    _initializeBox();
  }

  Future<void> _initializeBox() async {
    _box = await Hive.openBox<ChatMessage>(_boxName);
    _loadMessages();
  }

  void _loadMessages() {
    final messages = _box.values.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    state = state.copyWith(messages: messages);
  }

  Future<void> _saveMessage(ChatMessage message) async {
    await _box.put(message.id, message);
  }

  /// Send a user message and get AI response
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    print('📱 ChatProvider: Sending message: $content');

    final userMessage = ChatMessage(
      id: const Uuid().v4(),
      content: content.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );

    // Add user message
    final updatedMessages = [...state.messages, userMessage];
    state = state.copyWith(messages: updatedMessages, isTyping: true);
    await _saveMessage(userMessage);

    print('📱 ChatProvider: User message added, starting AI response...');

    try {
      // Prepare conversation history for API
      final conversationHistory = state.messages
          .where((msg) => !msg.isStreaming)
          .map((msg) => {
                'role': msg.isUser ? 'user' : 'assistant',
                'content': msg.content,
              })
          .toList();

      print('📱 ChatProvider: Conversation history prepared: ${conversationHistory.length} messages');

      // Create streaming AI message
      final aiMessageId = const Uuid().v4();
      final aiMessage = ChatMessage(
        id: aiMessageId,
        content: '',
        isUser: false,
        timestamp: DateTime.now(),
        isStreaming: true,
      );

      // Add empty AI message to show typing
      final messagesWithAI = [...updatedMessages, aiMessage];
      state = state.copyWith(messages: messagesWithAI);

      // Get settings for system prompt
      final settings = _ref.read(settingsProvider);

      print('📱 ChatProvider: Starting stream subscription...');

      // Cancel any existing stream subscription
      await _streamSubscription?.cancel();
      
      // Stream AI response
      String accumulatedContent = '';
      _streamSubscription = _deepSeekService
          .streamChatCompletion(
            message: content,
            systemPrompt: settings.systemPrompt,
            conversationHistory: conversationHistory,
          )
          .listen(
            (chunk) {
              print('📱 ChatProvider: Received chunk: $chunk');
              accumulatedContent += chunk;
              
              // Update the streaming message
              final updatedAIMessage = aiMessage.copyWith(
                content: accumulatedContent,
              );
              
              final updatedMessagesList = [...messagesWithAI];
              updatedMessagesList[updatedMessagesList.length - 1] = updatedAIMessage;
              
              state = state.copyWith(messages: updatedMessagesList);
            },
            onDone: () {
              print('📱 ChatProvider: Stream completed. Final content: $accumulatedContent');
              // Finalize the AI message
              final finalAIMessage = aiMessage.copyWith(
                content: accumulatedContent,
                isStreaming: false,
              );
              
              final finalMessages = [...messagesWithAI];
              finalMessages[finalMessages.length - 1] = finalAIMessage;
              
              state = state.copyWith(
                messages: finalMessages,
                isTyping: false,
                error: null,
              );
              
              _saveMessage(finalAIMessage);
            },
            onError: (error) {
              print('📱 ChatProvider: Stream error: $error');
              // Remove the streaming message and show error
              state = state.copyWith(
                messages: updatedMessages,
                isTyping: false,
                error: error.toString(),
              );
            },
          );
    } catch (e) {
      print('📱 ChatProvider: Exception in sendMessage: $e');
      state = state.copyWith(
        isTyping: false,
        error: e.toString(),
      );
    }
  }

  /// Retry last failed message
  Future<void> retryLastMessage() async {
    if (state.messages.isEmpty) return;
    
    final lastUserMessage = state.messages
        .lastWhere((msg) => msg.isUser, orElse: () => state.messages.last);
    
    if (lastUserMessage.isUser) {
      await sendMessage(lastUserMessage.content);
    }
  }

  /// Clear all messages
  Future<void> clearMessages() async {
    await _box.clear();
    state = const ChatState();
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _box.close();
    super.dispose();
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>(
  (ref) => ChatNotifier(ref),
);