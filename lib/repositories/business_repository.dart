import '../models/business.dart';
import '../services/database_service.dart';
import 'package:sqflite/sqflite.dart';

class BusinessRepository {
  final DatabaseService _db;

  BusinessRepository(this._db);

  Future<Business> get() async {
    final db = await _db.database;
    final maps = await db.query('business', limit: 1);
    if (maps.isNotEmpty) {
      return Business.fromMap(maps.first);
    }
    // Eğer veritabanında yoksa varsayılan oluştur ve kaydet
    final defaultBiz = Business.createDefault();
    await save(defaultBiz);
    return defaultBiz;
  }

  Future<void> save(Business business) async {
    final db = await _db.database;
    // Tek satır olmasını garanti etmek için REPLACE veya DELETE/INSERT kullanılabilir
    // Burada tablonun varlığından emin olmalıyız (v4 migration ile eklendi)
    await db.insert('business', business.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> update(Business business) async {
    final db = await _db.database;
    await db.update(
      'business',
      business.toMap(),
      where: 'id = ?',
      whereArgs: [business.id],
    );
  }
}
