import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/settings.dart';

class SettingsNotifier extends StateNotifier<AppSettings> {
  static const String _boxName = 'settings';
  late Box<AppSettings> _box;

  SettingsNotifier() : super(AppSettings()) {
    _initializeBox();
  }

  Future<void> _initializeBox() async {
    _box = await Hive.openBox<AppSettings>(_boxName);
    
    // Load existing settings or use defaults
    final savedSettings = _box.get('app_settings');
    if (savedSettings != null) {
      state = savedSettings;
    } else {
      // Save default settings
      await _saveSettings(state);
    }
  }

  Future<void> _saveSettings(AppSettings settings) async {
    await _box.put('app_settings', settings);
  }

  /// Update system prompt
  Future<void> updateSystemPrompt(String prompt) async {
    final newSettings = state.copyWith(systemPrompt: prompt);
    state = newSettings;
    await _saveSettings(newSettings);
  }

  /// Update theme mode
  Future<void> updateThemeMode(ThemeMode themeMode) async {
    final newSettings = state.copyWith(themeMode: themeMode);
    state = newSettings;
    await _saveSettings(newSettings);
  }

  /// Update primary color
  Future<void> updatePrimaryColor(Color color) async {
    final newSettings = state.copyWith(primaryColorValue: color.value);
    state = newSettings;
    await _saveSettings(newSettings);
  }

  /// Update secondary color
  Future<void> updateSecondaryColor(Color color) async {
    final newSettings = state.copyWith(secondaryColorValue: color.value);
    state = newSettings;
    await _saveSettings(newSettings);
  }

  /// Reset to defaults
  Future<void> resetToDefaults() async {
    final defaultSettings = AppSettings();
    state = defaultSettings;
    await _saveSettings(defaultSettings);
  }

  @override
  void dispose() {
    _box.close();
    super.dispose();
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>(
  (ref) => SettingsNotifier(),
);