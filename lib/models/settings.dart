import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'settings.g.dart';

@HiveType(typeId: 1)
class AppSettings extends HiveObject {
  @HiveField(0)
  final String systemPrompt;

  @HiveField(1)
  final int themeModeIndex;

  @HiveField(2)
  final int primaryColorValue;

  @HiveField(3)
  final int secondaryColorValue;

  AppSettings({
    this.systemPrompt = 'You are a helpful AI assistant. Keep responses concise and under 50 tokens.',
    this.themeModeIndex = 0, // 0 = system, 1 = light, 2 = dark
    this.primaryColorValue = 0xFF10A37F,
    this.secondaryColorValue = 0xFFFAF9F6,
  });

  Color get primaryColor => Color(primaryColorValue);
  Color get secondaryColor => Color(secondaryColorValue);

  ThemeMode get themeMode {
    switch (themeModeIndex) {
      case 1:
        return ThemeMode.light;
      case 2:
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  AppSettings copyWith({
    String? systemPrompt,
    ThemeMode? themeMode,
    int? primaryColorValue,
    int? secondaryColorValue,
  }) {
    int? newThemeModeIndex;
    if (themeMode != null) {
      switch (themeMode) {
        case ThemeMode.light:
          newThemeModeIndex = 1;
          break;
        case ThemeMode.dark:
          newThemeModeIndex = 2;
          break;
        case ThemeMode.system:
          newThemeModeIndex = 0;
          break;
      }
    }

    return AppSettings(
      systemPrompt: systemPrompt ?? this.systemPrompt,
      themeModeIndex: newThemeModeIndex ?? this.themeModeIndex,
      primaryColorValue: primaryColorValue ?? this.primaryColorValue,
      secondaryColorValue: secondaryColorValue ?? this.secondaryColorValue,
    );
  }

  @override
  String toString() {
    return 'AppSettings(systemPrompt: $systemPrompt, themeMode: $themeMode, primaryColor: $primaryColorValue, secondaryColor: $secondaryColorValue)';
  }
}