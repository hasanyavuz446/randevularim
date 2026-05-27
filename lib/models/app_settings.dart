import 'package:flutter/material.dart';

class AppSettings {
  final String themeId;
  final String languageCode;
  final ThemeMode themeMode;
  final bool globalNotificationsEnabled;
  final int reminderMinutes; // How many minutes before

  const AppSettings({
    required this.themeId,
    required this.languageCode,
    required this.themeMode,
    this.globalNotificationsEnabled = true,
    this.reminderMinutes = 30,
  });

  static const defaults = AppSettings(
    themeId: 'night_blue',
    languageCode: 'tr',
    themeMode: ThemeMode.system,
    globalNotificationsEnabled: true,
    reminderMinutes: 30,
  );

  AppSettings copyWith({
    String? themeId,
    String? languageCode,
    ThemeMode? themeMode,
    bool? globalNotificationsEnabled,
    int? reminderMinutes,
  }) {
    return AppSettings(
      themeId: themeId ?? this.themeId,
      languageCode: languageCode ?? this.languageCode,
      themeMode: themeMode ?? this.themeMode,
      globalNotificationsEnabled: globalNotificationsEnabled ?? this.globalNotificationsEnabled,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
    );
  }
}
