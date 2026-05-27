import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class BackupService {
  static const backupVersion = 9;
  static const _tableNames = [
    'customers',
    'appointments',
    'services',
    'staff',
    'business',
  ];
  static const _settingsKeys = [
    'settings_theme_id',
    'settings_theme_mode',
    'settings_global_notifications',
    'settings_reminder_minutes',
  ];

  final Database _database;
  final SharedPreferences _prefs;

  BackupService(this._database, this._prefs);

  Future<String> exportJson() async {
    final data = <String, Object?>{
      'version': backupVersion,
      'exported_at': DateTime.now().toIso8601String(),
    };
    for (final table in _tableNames) {
      data[table] = await _database.query(table);
    }
    data['settings'] = {
      for (final key in _settingsKeys)
        if (_prefs.containsKey(key)) key: _prefs.get(key),
    };
    return jsonEncode(data);
  }

  Future<void> restoreJson(String jsonString) async {
    final decoded = jsonDecode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Yedek dosyası geçersiz.');
    }
    final version = decoded['version'];
    if (version is! int || version > backupVersion) {
      throw const FormatException('Yedek sürümü desteklenmiyor.');
    }

    final records = <String, List<Map<String, Object?>>>{};
    for (final table in _tableNames) {
      final raw = decoded[table];
      if (raw == null && (table == 'business' || table == 'staff')) {
        continue;
      }
      if (raw is! List) {
        throw FormatException('$table kayıtları yedekte bulunamadı.');
      }
      records[table] = raw.map<Map<String, Object?>>((record) {
        if (record is! Map) {
          throw FormatException('$table kaydı geçersiz.');
        }
        return record.map(
          (key, value) => MapEntry(key.toString(), value as Object?),
        );
      }).toList();
    }

    await _database.transaction((txn) async {
      for (final table in [
        'appointments',
        'customers',
        'services',
        'staff',
        'business',
      ]) {
        if (!records.containsKey(table)) continue;
        await txn.delete(table);
        for (final record in records[table]!) {
          await txn.insert(
            table,
            record,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    });

    final settings = decoded['settings'];
    if (settings is Map) {
      await _restoreSettings(settings);
    }
  }

  Future<void> _restoreSettings(Map<dynamic, dynamic> settings) async {
    for (final key in _settingsKeys) {
      final value = settings[key];
      if (value is String) {
        await _prefs.setString(key, value);
      } else if (value is bool) {
        await _prefs.setBool(key, value);
      } else if (value is int) {
        await _prefs.setInt(key, value);
      }
    }
  }
}
