import '../models/customer.dart';
import '../services/database_service.dart';

class CustomerRepository {
  final DatabaseService _db;

  CustomerRepository(this._db);

  Future<List<Customer>> getAll() async {
    final db = await _db.database;
    final maps = await db.query('customers', orderBy: 'name ASC');
    return maps.map(Customer.fromMap).toList();
  }

  Future<Customer?> getById(String id) async {
    final db = await _db.database;
    final maps =
        await db.query('customers', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Customer.fromMap(maps.first);
  }

  Future<List<Customer>> search(String query) async {
    final db = await _db.database;
    final maps = await db.query(
      'customers',
      where: 'name LIKE ? OR phone LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
    return maps.map(Customer.fromMap).toList();
  }

  Future<void> save(Customer customer) async {
    final db = await _db.database;
    await db.insert('customers', customer.toMap());
  }

  Future<void> update(Customer customer) async {
    final db = await _db.database;
    await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }
}
