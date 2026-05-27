import 'package:sqflite/sqflite.dart';
import '../models/service.dart';
import '../services/database_service.dart';

class ServiceRepository {
  final DatabaseService _db;

  ServiceRepository(this._db);

  Future<List<Service>> getAll() async {
    final db = await _db.database;
    final maps =
        await db.query('services', orderBy: 'sort_order ASC, name ASC');
    return maps.map(Service.fromMap).toList();
  }

  Future<void> save(Service service) async {
    final db = await _db.database;
    await db.insert('services', service.toMap());
  }

  Future<void> update(Service service) async {
    final db = await _db.database;
    await db.update('services', service.toMap(),
        where: 'id = ?', whereArgs: [service.id]);
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('services', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> reorderAll(List<Service> services) async {
    final db = await _db.database;
    final batch = db.batch();
    for (var i = 0; i < services.length; i++) {
      batch.update(
        'services',
        {'sort_order': i},
        where: 'id = ?',
        whereArgs: [services[i].id],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> seedDefaults() async {
    final db = await _db.database;
    for (final s in Service.defaults) {
      await db.insert('services', s.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }
}
