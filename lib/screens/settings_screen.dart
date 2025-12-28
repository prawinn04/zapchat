import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/settings_provider.dart';
import '../providers/chat_session_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // App Info Section
          _buildSection(
            context,
            'App Information',
            [
              ListTile(
                leading: Container(
                  width: MediaQuery.of(context).size.width * 0.1, // 10% of screen width
                  height: MediaQuery.of(context).size.width * 0.1,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/fav.png',
                      width: MediaQuery.of(context).size.width * 0.08,
                      height: MediaQuery.of(context).size.width * 0.08,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.chat_bubble_outline,
                          color: theme.colorScheme.primary,
                          size: MediaQuery.of(context).size.width * 0.05,
                        );
                      },
                    ),
                  ),
                ),
                title: Text(
                  'ZapChat',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'AI-Powered Chat Application\nVersion 1.0.0',
                  style: GoogleFonts.inter(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Appearance Section
          _buildSection(
            context,
            'Appearance',
            [
              ListTile(
                leading: Icon(
                  Icons.palette_outlined,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                title: Text(
                  'Theme',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  _getThemeName(settings.themeMode),
                  style: GoogleFonts.inter(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                trailing: DropdownButton<ThemeMode>(
                  value: settings.themeMode,
                  underline: const SizedBox(),
                  items: [
                    DropdownMenuItem(
                      value: ThemeMode.system,
                      child: Text(
                        'System',
                        style: GoogleFonts.inter(),
                      ),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.light,
                      child: Text(
                        'Light',
                        style: GoogleFonts.inter(),
                      ),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.dark,
                      child: Text(
                        'Dark',
                        style: GoogleFonts.inter(),
                      ),
                    ),
                  ],
                  onChanged: (ThemeMode? newTheme) {
                    if (newTheme != null) {
                      ref.read(settingsProvider.notifier).updateThemeMode(newTheme);
                    }
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // AI Settings Section
          _buildSection(
            context,
            'AI Settings',
            [
              ListTile(
                leading: Icon(
                  Icons.smart_toy_outlined,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                title: Text(
                  'System Prompt',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  settings.systemPrompt,
                  style: GoogleFonts.inter(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => _showSystemPromptDialog(context, ref, settings.systemPrompt),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Data Management Section
          _buildSection(
            context,
            'Data Management',
            [
              ListTile(
                leading: Icon(
                  Icons.delete_sweep_outlined,
                  color: theme.colorScheme.error,
                ),
                title: Text(
                  'Clear All Chats',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.error,
                  ),
                ),
                subtitle: Text(
                  'Delete all chat history permanently',
                  style: GoogleFonts.inter(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                onTap: () => _showClearAllChatsDialog(context, ref),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // About Section
          _buildSection(
            context,
            'About',
            [
              ListTile(
                leading: Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                title: Text(
                  'About ZapChat',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  'Built with Flutter & AI',
                  style: GoogleFonts.inter(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                onTap: () => _showAboutDialog(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  String _getThemeName(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  void _showSystemPromptDialog(BuildContext context, WidgetRef ref, String currentPrompt) {
    final controller = TextEditingController(text: currentPrompt);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'System Prompt',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Enter system prompt for AI...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
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
              ref.read(settingsProvider.notifier).updateSystemPrompt(controller.text);
              Navigator.of(context).pop();
            },
            child: Text(
              'Save',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearAllChatsDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Clear All Chats',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete all chat history? This action cannot be undone.',
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
              ref.read(chatSessionProvider.notifier).clearAllSessions();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'All chats cleared successfully',
                    style: GoogleFonts.inter(),
                  ),
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(
              'Clear All',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    showAboutDialog(
      context: context,
      applicationName: 'ZapChat',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: screenWidth * 0.15, // 15% of screen width
        height: screenWidth * 0.15,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/images/fav.png',
            width: screenWidth * 0.12,
            height: screenWidth * 0.12,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.chat_bubble_outline,
                color: Colors.white,
                size: screenWidth * 0.08,
              );
            },
          ),
        ),
      ),
      children: [
        Text(
          'ZapChat is an AI-powered chat application built with Flutter. Experience seamless conversations with advanced AI technology.',
          style: GoogleFonts.inter(),
        ),
      ],
    );
  }
}