import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/chat_session_provider.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_sidebar.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showSidebar = false;

  @override
  void initState() {
    super.initState();
    // Create initial session if none exists after a delay to ensure provider is ready
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Wait a bit for the provider to initialize
      await Future.delayed(const Duration(milliseconds: 500));
      final chatState = ref.read(chatSessionProvider);
      if (chatState.activeSession == null && chatState.sessions.isEmpty) {
        ref.read(chatSessionProvider.notifier).createNewSession();
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      ref.read(chatSessionProvider.notifier).sendMessage(message);
      _messageController.clear();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients && mounted) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatSessionProvider);
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    // Listen for new messages and scroll to bottom
    ref.listen<ChatSessionState>(chatSessionProvider, (previous, next) {
      if (previous?.activeSession?.messages.length != next.activeSession?.messages.length) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      drawer: !isTablet && !_showSidebar ? Drawer(
        child: ChatSidebar(
          onClose: () {
            Navigator.of(context).pop();
          },
        ),
      ) : null,
      body: Stack(
        children: [
          // Main Chat Area
          Row(
            children: [
              // Sidebar for tablets only
              if (isTablet)
                ChatSidebar(
                  onClose: () {
                    setState(() {
                      _showSidebar = false;
                    });
                  },
                ),
              
              // Chat Content
              Expanded(
                child: Column(
                  children: [
                    // App Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        border: Border(
                          bottom: BorderSide(
                            color: theme.colorScheme.outline.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Row(
                          children: [
                            // Menu Button
                            IconButton(
                              onPressed: () {
                                if (isTablet) {
                                  setState(() {
                                    _showSidebar = !_showSidebar;
                                  });
                                } else {
                                  // For mobile, toggle overlay sidebar
                                  setState(() {
                                    _showSidebar = !_showSidebar;
                                  });
                                }
                              },
                              icon: Icon(
                                _showSidebar ? Icons.close : Icons.menu,
                                color: theme.colorScheme.onSurface,
                                size: 20,
                              ),
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                            
                            const SizedBox(width: 4),
                            
                            // Title with Images
                            Expanded(
                              child: Row(
                                children: [
                                  // Favicon
                                  Image.asset(
                                    'assets/images/favbgss.png',
                                    width: MediaQuery.of(context).size.width * 0.06, // 6% of screen width
                                    height: MediaQuery.of(context).size.width * 0.06,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      // Fallback to icon if image not found
                                      return Icon(
                                        Icons.chat_bubble_outline,
                                        size: MediaQuery.of(context).size.width * 0.05,
                                        color: theme.colorScheme.primary,
                                      );
                                    },
                                  ),
                                  
                                  SizedBox(width: MediaQuery.of(context).size.width * 0.02), // 2% spacing
                                  
                                  // App Name Image
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Image.asset(
                                          'assets/images/name_2_nobg.png',
                                          height: MediaQuery.of(context).size.width * 0.05, // 6% of screen width
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error, stackTrace) {
                                            // Fallback to text if image not found
                                            return Text(
                                              'ZapChat',
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: theme.colorScheme.primary,
                                              ),
                                            );
                                          },
                                        ),
                                        if (chatState.activeSession?.title != null && 
                                            chatState.activeSession!.title != 'New Chat')
                                          Text(
                                            chatState.activeSession!.title,
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w400,
                                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Settings Button (mobile only)
                            if (!isTablet)
                              IconButton(
                                onPressed: () {
                                  Navigator.of(context).pushNamed('/settings');
                                },
                                icon: Icon(
                                  Icons.settings_outlined,
                                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                                  size: 18,
                                ),
                                tooltip: 'Settings',
                                padding: const EdgeInsets.all(6),
                                constraints: const BoxConstraints(
                                  minWidth: 28,
                                  minHeight: 28,
                                ),
                              ),
                            
                            // New Chat Button
                            IconButton(
                              onPressed: () {
                                ref.read(chatSessionProvider.notifier).createNewSession();
                              },
                              icon: Icon(
                                Icons.add,
                                color: theme.colorScheme.primary,
                                size: 20,
                              ),
                              tooltip: 'New Chat',
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Chat Messages
                    Expanded(
                      child: chatState.isLoading
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Loading chat history...',
                                    style: GoogleFonts.inter(
                                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : chatState.activeSession == null || chatState.activeSession!.messages.isEmpty
                              ? _buildEmptyState(theme)
                              : ListView.builder(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.all(16),
                                  itemCount: chatState.activeSession!.messages.length,
                                  itemBuilder: (context, index) {
                                    final message = chatState.activeSession!.messages[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 16),
                                      child: ChatBubble(message: message),
                                    );
                                  },
                                ),
                    ),

                    // Error Message
                    if (chatState.error != null)
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: theme.colorScheme.onErrorContainer,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                chatState.error!,
                                style: GoogleFonts.inter(
                                  color: theme.colorScheme.onErrorContainer,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                ref.read(chatSessionProvider.notifier).clearError();
                              },
                              icon: Icon(
                                Icons.close,
                                color: theme.colorScheme.onErrorContainer,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Typing Indicator
                    if (chatState.isTyping)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.smart_toy,
                                color: theme.colorScheme.onSecondary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'AI is typing...',
                              style: GoogleFonts.inter(
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Message Input
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        border: Border(
                          top: BorderSide(
                            color: theme.colorScheme.outline.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: InputDecoration(
                                hintText: 'Type your message...',
                                hintStyle: GoogleFonts.inter(
                                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide(
                                    color: theme.colorScheme.outline.withOpacity(0.3),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide(
                                    color: theme.colorScheme.outline.withOpacity(0.3),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide(
                                    color: theme.colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              style: GoogleFonts.inter(
                                color: theme.colorScheme.onSurface,
                              ),
                              maxLines: null,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: chatState.isTyping ? null : _sendMessage,
                              icon: Icon(
                                Icons.send,
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Overlay Sidebar for Mobile
          if (_showSidebar && !isTablet)
            _buildOverlaySidebar(theme),
        ],
      ),
    );
  }

  Widget _buildOverlaySidebar(ThemeData theme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Stack(
        children: [
          // Background overlay with fade
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _showSidebar ? 1.0 : 0.0,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _showSidebar = false;
                });
              },
              child: Container(
                color: Colors.black.withOpacity(0.5),
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
          
          // Sidebar content sliding from left
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: _showSidebar ? 0 : -280, // Slide from left
            top: 0,
            bottom: 0,
            child: Container(
              width: 280, // Fixed width like ChatGPT
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(2, 0),
                  ),
                ],
              ),
              child: ChatSidebar(
                onClose: () {
                  setState(() {
                    _showSidebar = false;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: screenWidth * 0.2, // 20% of screen width
            height: screenWidth * 0.2,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/fav.png',
                width: screenWidth * 0.15,
                height: screenWidth * 0.15,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.chat_bubble_outline,
                    size: screenWidth * 0.1,
                    color: theme.colorScheme.primary,
                  );
                },
              ),
            ),
          ),
          SizedBox(height: screenHeight * 0.03), // 3% of screen height
          Text(
            'Welcome to ZapChat',
            style: GoogleFonts.inter(
              fontSize: screenWidth * 0.06, // 6% of screen width
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: screenHeight * 0.01), // 1% of screen height
          Text(
            'Start a conversation with AI',
            style: GoogleFonts.inter(
              fontSize: screenWidth * 0.04, // 4% of screen width
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          SizedBox(height: screenHeight * 0.04), // 4% of screen height
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.06, // 6% of screen width
              vertical: screenHeight * 0.02, // 2% of screen height
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  '💡 Tips:',
                  style: GoogleFonts.inter(
                    fontSize: screenWidth * 0.035, // 3.5% of screen width
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: screenHeight * 0.01), // 1% of screen height
                Text(
                  '• Ask questions about any topic\n'
                  '• Get help with coding problems\n'
                  '• Have natural conversations\n'
                  '• Your chat history is automatically saved',
                  style: GoogleFonts.inter(
                    fontSize: screenWidth * 0.032, // 3.2% of screen width
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}