import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/chat_message.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _buildAvatar(context, false),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser 
                    ? theme.colorScheme.primary
                    : theme.colorScheme.secondary,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Use Markdown for AI messages, plain text for user messages
                  if (isUser)
                    Text(
                      message.content,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        height: 1.4,
                        color: Colors.white,
                      ),
                    )
                  else
                    MarkdownBody(
                      data: message.content,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet(
                        p: GoogleFonts.inter(
                          fontSize: 15,
                          height: 1.4,
                          color: theme.brightness == Brightness.dark
                              ? Colors.black87
                              : Colors.black87,
                        ),
                        strong: GoogleFonts.inter(
                          fontSize: 15,
                          height: 1.4,
                          fontWeight: FontWeight.bold,
                          color: theme.brightness == Brightness.dark
                              ? Colors.black87
                              : Colors.black87,
                        ),
                        em: GoogleFonts.inter(
                          fontSize: 15,
                          height: 1.4,
                          fontStyle: FontStyle.italic,
                          color: theme.brightness == Brightness.dark
                              ? Colors.black87
                              : Colors.black87,
                        ),
                        code: GoogleFonts.jetBrainsMono(
                          fontSize: 14,
                          backgroundColor: theme.colorScheme.surface.withOpacity(0.3),
                          color: theme.colorScheme.primary,
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: theme.colorScheme.surface.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
                        codeblockPadding: const EdgeInsets.all(12),
                        blockquote: GoogleFonts.inter(
                          fontSize: 15,
                          height: 1.4,
                          fontStyle: FontStyle.italic,
                          color: (theme.brightness == Brightness.dark
                              ? Colors.black87
                              : Colors.black87).withOpacity(0.8),
                        ),
                        blockquoteDecoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: theme.colorScheme.primary,
                              width: 3,
                            ),
                          ),
                        ),
                        h1: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.brightness == Brightness.dark
                              ? Colors.black87
                              : Colors.black87,
                        ),
                        h2: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.brightness == Brightness.dark
                              ? Colors.black87
                              : Colors.black87,
                        ),
                        h3: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.brightness == Brightness.dark
                              ? Colors.black87
                              : Colors.black87,
                        ),
                        listBullet: GoogleFonts.inter(
                          fontSize: 15,
                          height: 1.4,
                          color: theme.brightness == Brightness.dark
                              ? Colors.black87
                              : Colors.black87,
                        ),
                        a: GoogleFonts.inter(
                          fontSize: 15,
                          height: 1.4,
                          color: theme.colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  if (message.isStreaming) ...[
                    const SizedBox(height: 8),
                    _buildTypingIndicator(context, isUser),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 12),
            _buildAvatar(context, true),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, bool isUser) {
    final theme = Theme.of(context);
    
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isUser 
            ? theme.colorScheme.primary
            : theme.colorScheme.secondary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Icon(
        isUser ? Icons.person : Icons.smart_toy,
        size: 18,
        color: isUser 
            ? Colors.white
            : theme.brightness == Brightness.dark
                ? Colors.black87
                : Colors.black87,
      ),
    );
  }

  Widget _buildTypingIndicator(BuildContext context, bool isUser) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDot(context, isUser, 0),
        const SizedBox(width: 4),
        _buildDot(context, isUser, 1),
        const SizedBox(width: 4),
        _buildDot(context, isUser, 2),
      ],
    );
  }

  Widget _buildDot(BuildContext context, bool isUser, int index) {
    final theme = Theme.of(context);
    
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 200)),
      tween: Tween(begin: 0.4, end: 1.0),
      builder: (context, value, child) {
        return AnimatedOpacity(
          opacity: value,
          duration: const Duration(milliseconds: 300),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: (isUser 
                  ? Colors.white
                  : theme.brightness == Brightness.dark
                      ? Colors.black54
                      : Colors.black54).withOpacity(value),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}