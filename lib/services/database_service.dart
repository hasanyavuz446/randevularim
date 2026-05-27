import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/service.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  static Database? _database;

  DatabaseService._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'randevularim.db');
    return _openAtPath(path);
  }

  Future<Database> _openAtPath(String path) {
    return openDatabase(
      path,
      version: 9,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  @visibleForTesting
  Future<Database> openForTesting(String path) => _openAtPath(path);

  Future<void> _onCreate(Database db, int version) async {
    await _createCustomersTable(db);
    await _createAppointmentsTable(db);
    await _createServicesTable(db);
    await _createStaffTable(db);
    await _createBusinessTable(db);
    await _seedServices(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createServicesTable(db);
      await _seedServices(db);
      await _migrateAppointments(db);
    }
    if (oldVersion < 3) {
      await _migrateCustomers(db);
    }
    if (oldVersion < 4) {
      await _migrateToV4(db);
    }
    if (oldVersion < 5) {
      await _createBusinessTable(db);
      await _createStaffTable(db);
      await _migrateToV4(db);
    }
    if (oldVersion < 6) {
      await _migrateToV6(db);
    }
    if (oldVersion < 7) {
      // Force verify columns for v6 again to be absolutely sure
      await _migrateToV6(db);
    }
    if (oldVersion < 8) {
      await _migrateToV8(db);
    }
    if (oldVersion < 9) {
      await _migrateToV9(db);
    }
  }

  Future<void> _createCustomersTable(Database db) => db.execute('''
    CREATE TABLE IF NOT EXISTS customers (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      phone TEXT NOT NULL,
      service_notes TEXT DEFAULT '',
      general_notes TEXT DEFAULT '',
      created_at INTEGER NOT NULL
    )
  ''');

  Future<void> _createAppointmentsTable(Database db) => db.execute('''
    CREATE TABLE IF NOT EXISTS appointments (
      id TEXT PRIMARY KEY,
      customer_id TEXT NOT NULL,
      customer_name TEXT NOT NULL,
      customer_phone TEXT NOT NULL,
      date_time INTEGER NOT NULL,
      duration_minutes INTEGER NOT NULL,
      service_id TEXT NOT NULL DEFAULT 'svc_genel',
      service_name TEXT NOT NULL DEFAULT 'Genel Randevu',
      service_color TEXT NOT NULL DEFAULT '#5856D6',
      notes TEXT DEFAULT '',
      status TEXT NOT NULL DEFAULT 'scheduled',
      total_price REAL DEFAULT 0.0,
      staff_id TEXT DEFAULT '',
      notifications_enabled INTEGER DEFAULT 1,
      reminder_minutes INTEGER DEFAULT 30,
      start_notification_enabled INTEGER DEFAULT 1,
      FOREIGN KEY (customer_id) REFERENCES customers(id)
    )
  ''');

  Future<void> _createServicesTable(Database db) => db.execute('''
    CREATE TABLE IF NOT EXISTS services (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      duration_minutes INTEGER NOT NULL,
      default_duration_minutes INTEGER NOT NULL,
      color_hex TEXT NOT NULL,
      sort_order INTEGER NOT NULL DEFAULT 0,
      price REAL DEFAULT 0.0,
      description TEXT DEFAULT '',
      is_active INTEGER DEFAULT 1
    )
  ''');

  Future<void> _createStaffTable(Database db) => db.execute('''
    CREATE TABLE IF NOT EXISTS staff (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      phone TEXT DEFAULT '',
      role TEXT DEFAULT '',
      is_active INTEGER DEFAULT 1,
      color_hex TEXT DEFAULT '#5856D6',
      services_provided TEXT DEFAULT '',
      working_days TEXT DEFAULT '1,2,3,4,5,6'
    )
  ''');

  Future<void> _createBusinessTable(Database db) => db.execute('''
    CREATE TABLE IF NOT EXISTS business (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      category TEXT DEFAULT 'Genel',
      phone TEXT DEFAULT '',
      address TEXT DEFAULT '',
      logo_url TEXT DEFAULT '',
      working_days TEXT DEFAULT '1,2,3,4,5,6',
      opening_time TEXT DEFAULT '09:00',
      closing_time TEXT DEFAULT '19:00',
      appointment_interval INTEGER DEFAULT 30,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
  ''');

  Future<void> _seedServices(Database db) async {
    final count =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM services'),
        ) ??
        0;
    if (count > 0) return;
    for (final s in Service.defaults) {
      await db.insert(
        'services',
        s.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<void> _migrateAppointments(Database db) async {
    await _addColumnIfMissing(
      db,
      'appointments',
      'service_id',
      'TEXT NOT NULL DEFAULT "svc_genel"',
    );
    await _addColumnIfMissing(
      db,
      'appointments',
      'service_name',
      'TEXT NOT NULL DEFAULT "Genel Randevu"',
    );
    await _addColumnIfMissing(
      db,
      'appointments',
      'service_color',
      'TEXT NOT NULL DEFAULT "#5856D6"',
    );
  }

  Future<void> _migrateCustomers(Database db) async {
    final columns = await _columnNames(db, 'customers');
    if (columns.contains('hair_notes') && !columns.contains('service_notes')) {
      await db.execute(
        'ALTER TABLE customers RENAME COLUMN hair_notes TO service_notes',
      );
      return;
    }
    await _addColumnIfMissing(
      db,
      'customers',
      'service_notes',
      'TEXT DEFAULT ""',
    );
  }

  Future<void> _migrateToV4(Database db) async {
    await _addColumnIfMissing(db, 'services', 'price', 'REAL DEFAULT 0.0');
    await _addColumnIfMissing(db, 'services', 'description', 'TEXT DEFAULT ""');
    await _addColumnIfMissing(db, 'services', 'is_active', 'INTEGER DEFAULT 1');
    await _addColumnIfMissing(
      db,
      'appointments',
      'total_price',
      'REAL DEFAULT 0.0',
    );
    await _addColumnIfMissing(
      db,
      'appointments',
      'staff_id',
      'TEXT DEFAULT ""',
    );
    await _createStaffTable(db);
    await _createBusinessTable(db);
  }

  Future<void> _migrateToV6(Database db) async {
    await _addColumnIfMissing(
      db,
      'appointments',
      'notifications_enabled',
      'INTEGER DEFAULT 1',
    );
  }

  Future<void> _migrateToV8(Database db) async {
    final names = await _columnNames(db, 'services');
    if (!names.contains('duration_minutes')) {
      await _addColumnIfMissing(
        db,
        'services',
        'duration_minutes',
        'INTEGER NOT NULL DEFAULT 30',
      );
      if (names.contains('default_duration_minutes')) {
        await db.execute(
          'UPDATE services SET duration_minutes = default_duration_minutes',
        );
      }
    }
    if (!names.contains('default_duration_minutes')) {
      await _addColumnIfMissing(
        db,
        'services',
        'default_duration_minutes',
        'INTEGER NOT NULL DEFAULT 30',
      );
      await db.execute(
        'UPDATE services SET default_duration_minutes = duration_minutes',
      );
    }
  }

  Future<void> _migrateToV9(Database db) async {
    await _addColumnIfMissing(
      db,
      'appointments',
      'reminder_minutes',
      'INTEGER DEFAULT 30',
    );
    await _addColumnIfMissing(
      db,
      'appointments',
      'start_notification_enabled',
      'INTEGER DEFAULT 1',
    );
  }

  Future<Set<String>> _columnNames(Database db, String table) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    return columns.map((column) => column['name'] as String).toSet();
  }

  Future<void> _addColumnIfMissing(
    Database db,
    String table,
    String column,
    String declaration,
  ) async {
    if ((await _columnNames(db, table)).contains(column)) return;
    await db.execute('ALTER TABLE $table ADD COLUMN $column $declaration');
  }
}
