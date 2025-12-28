import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/chat_session.dart';
import '../models/chat_message.dart';
import '../services/deepseek_service.dart';
import 'settings_provider.dart';

class ChatSessionState {
  final List<ChatSession> sessions;
  final ChatSession? activeSession;
  final bool isLoading;
  final String? error;
  final bool isTyping;

  const ChatSessionState({
    this.sessions = const [],
    this.activeSession,
    this.isLoading = false,
    this.error,
    this.isTyping = false,
  });

  ChatSessionState copyWith({
    List<ChatSession>? sessions,
    ChatSession? activeSession,
    bool? isLoading,
    String? error,
    bool? isTyping,
  }) {
    return ChatSessionState(
      sessions: sessions ?? this.sessions,
      activeSession: activeSession ?? this.activeSession,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isTyping: isTyping ?? this.isTyping,
    );
  }
}

class ChatSessionNotifier extends StateNotifier<ChatSessionState> {
  static const String _boxName = 'chat_sessions';
  Box<ChatSession>? _box;
  final DeepSeekService _deepSeekService;
  final Ref _ref;
  StreamSubscription<String>? _streamSubscription;
  bool _isInitialized = false;

  ChatSessionNotifier(this._ref) 
      : _deepSeekService = DeepSeekService(),
        super(const ChatSessionState()) {
    _initializeBox();
  }

  Future<void> _initializeBox() async {
    state = state.copyWith(isLoading: true);
    try {
      _box = await Hive.openBox<ChatSession>(_boxName);
      _isInitialized = true;
      _loadSessions();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to initialize storage: $e',
      );
    }
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized || _box == null) {
      await _initializeBox();
    }
  }

  void _loadSessions() {
    if (_box == null) return;
    
    final sessions = _box!.values.toList()
      ..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
    
    // Find active session or create new one if none exists
    ChatSession? activeSession = sessions.where((s) => s.isActive).firstOrNull;
    
    if (activeSession == null && sessions.isNotEmpty) {
      activeSession = sessions.first;
    }
    
    state = state.copyWith(
      sessions: sessions,
      activeSession: activeSession,
    );
  }

  Future<void> _saveSession(ChatSession session) async {
    await _ensureInitialized();
    if (_box != null) {
      await _box!.put(session.id, session);
    }
  }

  /// Create a new chat session
  Future<void> createNewSession() async {
    await _ensureInitialized();
    
    // Deactivate current session
    if (state.activeSession != null) {
      final updatedCurrentSession = state.activeSession!.copyWith(isActive: false);
      await _saveSession(updatedCurrentSession);
    }

    final newSession = ChatSession(
      id: const Uuid().v4(),
      title: 'New Chat',
      createdAt: DateTime.now(),
      lastMessageAt: DateTime.now(),
      messages: [],
      isActive: true,
    );

    await _saveSession(newSession);
    
    final updatedSessions = [newSession, ...state.sessions];
    state = state.copyWith(
      sessions: updatedSessions,
      activeSession: newSession,
      error: null,
    );
  }

  /// Switch to an existing session
  Future<void> switchToSession(String sessionId) async {
    await _ensureInitialized();
    
    final session = state.sessions.where((s) => s.id == sessionId).firstOrNull;
    if (session == null) return;

    // Deactivate current session
    if (state.activeSession != null) {
      final updatedCurrentSession = state.activeSession!.copyWith(isActive: false);
      await _saveSession(updatedCurrentSession);
    }

    // Activate new session
    final updatedSession = session.copyWith(isActive: true);
    await _saveSession(updatedSession);

    final updatedSessions = state.sessions.map((s) => 
      s.id == sessionId ? updatedSession : s.copyWith(isActive: false)
    ).toList();

    state = state.copyWith(
      sessions: updatedSessions,
      activeSession: updatedSession,
    );
  }

  /// Send a message in the active session
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    await _ensureInitialized();

    // Create new session if none exists
    if (state.activeSession == null) {
      await createNewSession();
    }

    final activeSession = state.activeSession!;

    // Check if conversation limit reached
    if (activeSession.hasReachedLimit()) {
      state = state.copyWith(
        error: 'Conversation limit reached. Please start a new chat.',
      );
      return;
    }

    final userMessage = ChatMessage(
      id: const Uuid().v4(),
      content: content.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );

    // Add user message to session
    final updatedMessages = [...activeSession.messages, userMessage];
    final updatedSession = activeSession.copyWith(
      messages: updatedMessages,
      lastMessageAt: DateTime.now(),
      title: activeSession.messages.isEmpty ? activeSession.generateTitle() : activeSession.title,
    );

    state = state.copyWith(
      activeSession: updatedSession,
      isTyping: true,
    );

    await _saveSession(updatedSession);

    try {
      // Prepare conversation history for API
      final conversationHistory = updatedMessages
          .where((msg) => !msg.isStreaming)
          .map((msg) => {
                'role': msg.isUser ? 'user' : 'assistant',
                'content': msg.content,
              })
          .toList();

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
      final sessionWithAI = updatedSession.copyWith(messages: messagesWithAI);
      
      state = state.copyWith(activeSession: sessionWithAI);

      // Get settings for system prompt
      final settings = _ref.read(settingsProvider);

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
              accumulatedContent += chunk;
              
              // Update the streaming message
              final updatedAIMessage = aiMessage.copyWith(
                content: accumulatedContent,
              );
              
              final updatedMessagesList = [...messagesWithAI];
              updatedMessagesList[updatedMessagesList.length - 1] = updatedAIMessage;
              
              final updatedSessionWithContent = sessionWithAI.copyWith(
                messages: updatedMessagesList,
              );
              
              state = state.copyWith(activeSession: updatedSessionWithContent);
            },
            onDone: () {
              // Finalize the AI message
              final finalAIMessage = aiMessage.copyWith(
                content: accumulatedContent,
                isStreaming: false,
              );
              
              final finalMessages = [...messagesWithAI];
              finalMessages[finalMessages.length - 1] = finalAIMessage;
              
              final finalSession = sessionWithAI.copyWith(
                messages: finalMessages,
                lastMessageAt: DateTime.now(),
              );
              
              state = state.copyWith(
                activeSession: finalSession,
                isTyping: false,
                error: null,
              );
              
              // Update sessions list
              final updatedSessions = state.sessions.map((s) => 
                s.id == finalSession.id ? finalSession : s
              ).toList();
              
              state = state.copyWith(sessions: updatedSessions);
              
              _saveSession(finalSession);
            },
            onError: (error) {
              // Remove the streaming message and show error
              state = state.copyWith(
                activeSession: updatedSession,
                isTyping: false,
                error: error.toString(),
              );
            },
          );
    } catch (e) {
      state = state.copyWith(
        isTyping: false,
        error: e.toString(),
      );
    }
  }

  /// Delete a chat session
  Future<void> deleteSession(String sessionId) async {
    await _ensureInitialized();
    if (_box != null) {
      await _box!.delete(sessionId);
    }
    
    final updatedSessions = state.sessions.where((s) => s.id != sessionId).toList();
    
    ChatSession? newActiveSession = state.activeSession;
    if (state.activeSession?.id == sessionId) {
      newActiveSession = updatedSessions.isNotEmpty ? updatedSessions.first : null;
      if (newActiveSession != null) {
        final activatedSession = newActiveSession.copyWith(isActive: true);
        await _saveSession(activatedSession);
        newActiveSession = activatedSession;
      }
    }
    
    state = state.copyWith(
      sessions: updatedSessions,
      activeSession: newActiveSession,
    );
  }

  /// Clear all chat sessions
  Future<void> clearAllSessions() async {
    await _ensureInitialized();
    if (_box != null) {
      await _box!.clear();
    }
    
    state = const ChatSessionState();
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _box?.close();
    super.dispose();
  }
}

final chatSessionProvider = StateNotifierProvider<ChatSessionNotifier, ChatSessionState>(
  (ref) => ChatSessionNotifier(ref),
);