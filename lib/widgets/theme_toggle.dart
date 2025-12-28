import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';

class ThemeToggle extends ConsumerWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    return PopupMenuButton<ThemeMode>(
      icon: Icon(_getThemeIcon(settings.themeMode)),
      onSelected: (ThemeMode themeMode) {
        settingsNotifier.updateThemeMode(themeMode);
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: ThemeMode.system,
          child: Row(
            children: [
              Icon(
                Icons.brightness_auto,
                color: settings.themeMode == ThemeMode.system
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              const SizedBox(width: 12),
              Text(
                'System',
                style: TextStyle(
                  color: settings.themeMode == ThemeMode.system
                      ? Theme.of(context).colorScheme.primary
                      : null,
                  fontWeight: settings.themeMode == ThemeMode.system
                      ? FontWeight.w600
                      : null,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: ThemeMode.light,
          child: Row(
            children: [
              Icon(
                Icons.light_mode,
                color: settings.themeMode == ThemeMode.light
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              const SizedBox(width: 12),
              Text(
                'Light',
                style: TextStyle(
                  color: settings.themeMode == ThemeMode.light
                      ? Theme.of(context).colorScheme.primary
                      : null,
                  fontWeight: settings.themeMode == ThemeMode.light
                      ? FontWeight.w600
                      : null,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: ThemeMode.dark,
          child: Row(
            children: [
              Icon(
                Icons.dark_mode,
                color: settings.themeMode == ThemeMode.dark
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              const SizedBox(width: 12),
              Text(
                'Dark',
                style: TextStyle(
                  color: settings.themeMode == ThemeMode.dark
                      ? Theme.of(context).colorScheme.primary
                      : null,
                  fontWeight: settings.themeMode == ThemeMode.dark
                      ? FontWeight.w600
                      : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getThemeIcon(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }
}