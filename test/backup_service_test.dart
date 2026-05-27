import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:randevularim/services/backup_service.dart';
import 'package:randevularim/services/database_service.dart';

void main() {
  late Database database;
  late File databaseFile;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'settings_theme_id': 'night_blue',
      'settings_reminder_minutes': 30,
    });
    databaseFile = File(
      '${Directory.systemTemp.path}/randevularim_backup_${DateTime.now().microsecondsSinceEpoch}.db',
    );
    database = await DatabaseService.instance.openForTesting(databaseFile.path);
  });

  tearDown(() async {
    await database.close();
    if (databaseFile.existsSync()) databaseFile.deleteSync();
  });

  test('export and restore preserves business and settings data', () async {
    final prefs = await SharedPreferences.getInstance();
    final service = BackupService(database, prefs);

    await database.insert('customers', {
      'id': 'customer-1',
      'name': 'Ada',
      'phone': '555',
      'created_at': 1,
    });
    await database.insert('business', {
      'id': 'business-1',
      'name': 'Salon',
      'created_at': 1,
      'updated_at': 1,
    });

    final backup = await service.exportJson();
    await database.delete('customers');
    await database.delete('business');
    await prefs.setString('settings_theme_id', 'forest');

    await service.restoreJson(backup);

    expect((await database.query('customers')).single['name'], 'Ada');
    expect((await database.query('business')).single['name'], 'Salon');
    expect(prefs.getString('settings_theme_id'), 'night_blue');
  });

  test('invalid backup is rejected without deleting current data', () async {
    final service = BackupService(
      database,
      await SharedPreferences.getInstance(),
    );
    await database.insert('customers', {
      'id': 'customer-1',
      'name': 'Ada',
      'phone': '555',
      'created_at': 1,
    });

    expect(
      () => service.restoreJson('{"appointments": []}'),
      throwsA(isA<FormatException>()),
    );
    expect((await database.query('customers')).length, 1);
  });
}
