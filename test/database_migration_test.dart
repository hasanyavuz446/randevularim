import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:randevularim/services/database_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test(
    'upgrade completes missing columns even after a partial older migration',
    () async {
      final file = File(
        '${Directory.systemTemp.path}/randevularim_migration_${DateTime.now().microsecondsSinceEpoch}.db',
      );
      final oldDb = await databaseFactory.openDatabase(
        file.path,
        options: OpenDatabaseOptions(
          version: 3,
          onCreate: (db, _) async {
            await db.execute('''
            CREATE TABLE customers (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              phone TEXT NOT NULL,
              service_notes TEXT DEFAULT '',
              created_at INTEGER NOT NULL
            )
          ''');
            await db.execute('''
            CREATE TABLE appointments (
              id TEXT PRIMARY KEY,
              customer_id TEXT NOT NULL,
              customer_name TEXT NOT NULL,
              customer_phone TEXT NOT NULL,
              date_time INTEGER NOT NULL,
              duration_minutes INTEGER NOT NULL,
              service_id TEXT,
              service_name TEXT,
              service_color TEXT
            )
          ''');
            await db.execute('''
            CREATE TABLE services (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              color_hex TEXT NOT NULL,
              sort_order INTEGER NOT NULL DEFAULT 0,
              price REAL DEFAULT 0.0
            )
          ''');
          },
        ),
      );
      await oldDb.close();

      final upgraded = await DatabaseService.instance.openForTesting(file.path);
      final serviceColumns = await _columns(upgraded, 'services');
      final appointmentColumns = await _columns(upgraded, 'appointments');

      expect(
        serviceColumns,
        containsAll([
          'price',
          'description',
          'is_active',
          'duration_minutes',
          'default_duration_minutes',
        ]),
      );
      expect(
        appointmentColumns,
        containsAll([
          'total_price',
          'staff_id',
          'notifications_enabled',
          'reminder_minutes',
          'start_notification_enabled',
        ]),
      );

      await upgraded.close();
      if (file.existsSync()) file.deleteSync();
    },
  );
}

Future<Set<String>> _columns(Database db, String table) async {
  final values = await db.rawQuery('PRAGMA table_info($table)');
  return values.map((value) => value['name'] as String).toSet();
}
