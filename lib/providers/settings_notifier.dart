import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_settings.dart';
import '../services/settings_service.dart';

class SettingsNotifier extends StateNotifier<AppSettings> {
  final SettingsService _service;

  SettingsNotifier(this._service) : super(_service.load());

  void reload() {
    state = _service.load();
  }

  void setTheme(String themeId) {
    state = state.copyWith(themeId: themeId);
    _service.save(state);
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _service.save(state);
  }

  void setGlobalNotifications(bool enabled) {
    state = state.copyWith(globalNotificationsEnabled: enabled);
    _service.save(state);
  }

  void setReminderMinutes(int minutes) {
    state = state.copyWith(reminderMinutes: minutes);
    _service.save(state);
  }
}
