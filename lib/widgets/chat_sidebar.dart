import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/chat_session.dart';
import '../providers/chat_session_provider.dart';

class ChatSidebar extends ConsumerWidget {
  final VoidCallback? onClose;

  const ChatSidebar({
    super.key,
    this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatSessionProvider);
    final theme = Theme.of(context);

    return Container(
      width: 280, // Match overlay width
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12), // Reduced from 16
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Chat History',
                    style: GoogleFonts.inter(
                      fontSize: 16, // Reduced from 18
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/settings');
                  },
                  icon: Icon(
                    Icons.settings_outlined,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    size: 18, // Smaller icon
                  ),
                  tooltip: 'Settings',
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                ),
                if (onClose != null)
                  IconButton(
                    onPressed: onClose,
                    icon: Icon(
                      Icons.close,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      size: 18, // Smaller icon
                    ),
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                  ),
              ],
            ),
          ),

          // New Chat Button
          Padding(
            padding: const EdgeInsets.all(12), // Reduced from 16
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(chatSessionProvider.notifier).createNewSession();
                },
                icon: const Icon(Icons.add, size: 16), // Smaller icon
                label: Text(
                  'New Chat',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    fontSize: 14, // Smaller text
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 10), // Reduced padding
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),

          // Chat Sessions List
          Expanded(
            child: chatState.sessions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 48,
                          color: theme.colorScheme.onSurface.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No chat history',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start a new conversation',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: theme.colorScheme.onSurface.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 6), // Reduced padding
                    itemCount: chatState.sessions.length,
                    itemBuilder: (context, index) {
                      final session = chatState.sessions[index];
                      final isActive = session.id == chatState.activeSession?.id;

                      return ChatSessionTile(
                        session: session,
                        isActive: isActive,
                        onTap: () {
                          ref.read(chatSessionProvider.notifier)
                              .switchToSession(session.id);
                        },
                        onDelete: () {
                          ref.read(chatSessionProvider.notifier)
                              .deleteSession(session.id);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class ChatSessionTile extends StatelessWidget {
  final ChatSession session;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ChatSessionTile({
    super.key,
    required this.session,
    required this.isActive,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, HH:mm');

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1), // Reduced margin
      decoration: BoxDecoration(
        color: isActive 
            ? theme.colorScheme.primary.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6), // Smaller radius
        border: isActive 
            ? Border.all(
                color: theme.colorScheme.primary.withOpacity(0.3),
                width: 1,
              )
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), // Reduced padding
        onTap: onTap,
        leading: Icon(
          Icons.chat_bubble_outline,
          size: 16, // Smaller icon
          color: isActive 
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface.withOpacity(0.6),
        ),
        title: Text(
          session.title,
          style: GoogleFonts.inter(
            fontSize: 12, // Smaller text
            fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
            color: isActive 
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          dateFormat.format(session.lastMessageAt),
          style: GoogleFonts.inter(
            fontSize: 10, // Smaller text
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            size: 14, // Smaller icon
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
          onSelected: (value) {
            if (value == 'delete') {
              _showDeleteDialog(context);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(
                    Icons.delete_outline,
                    size: 14, // Smaller icon
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Delete',
                    style: GoogleFonts.inter(
                      color: theme.colorScheme.error,
                      fontSize: 12, // Smaller text
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Chat',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete this chat? This action cannot be undone.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDelete();
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}