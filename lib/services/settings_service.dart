import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';

class SettingsService {
  static const _themeKey = 'settings_theme_id';
  static const _langKey = 'settings_language_code';
  static const _modeKey = 'settings_theme_mode';
  static const _notifKey = 'settings_global_notifications';
  static const _remindKey = 'settings_reminder_minutes';

  final SharedPreferences _prefs;

  SettingsService(this._prefs);

  AppSettings load() {
    return AppSettings(
      themeId: _prefs.getString(_themeKey) ?? AppSettings.defaults.themeId,
      languageCode: AppSettings.defaults.languageCode,
      themeMode: _modeFromString(_prefs.getString(_modeKey)),
      globalNotificationsEnabled:
          _prefs.getBool(_notifKey) ??
          AppSettings.defaults.globalNotificationsEnabled,
      reminderMinutes:
          _prefs.getInt(_remindKey) ?? AppSettings.defaults.reminderMinutes,
    );
  }

  Future<void> save(AppSettings settings) async {
    await _prefs.setString(_themeKey, settings.themeId);
    await _prefs.setString(_langKey, settings.languageCode);
    await _prefs.setString(_modeKey, settings.themeMode.name);
    await _prefs.setBool(_notifKey, settings.globalNotificationsEnabled);
    await _prefs.setInt(_remindKey, settings.reminderMinutes);
  }

  ThemeMode _modeFromString(String? value) {
    return ThemeMode.values.firstWhere(
      (m) => m.name == value,
      orElse: () => ThemeMode.system,
    );
  }
}
