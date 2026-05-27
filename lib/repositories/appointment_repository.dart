import '../models/appointment.dart';
import '../models/enums.dart';
import '../services/database_service.dart';

class AppointmentRepository {
  final DatabaseService _db;

  AppointmentRepository(this._db);

  Future<List<Appointment>> getAll() async {
    final db = await _db.database;
    final maps = await db.query('appointments', orderBy: 'date_time ASC');
    return maps.map(Appointment.fromMap).toList();
  }

  Future<List<Appointment>> getByCustomer(String customerId) async {
    final db = await _db.database;
    final maps = await db.query(
      'appointments',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'date_time DESC',
    );
    return maps.map(Appointment.fromMap).toList();
  }

  Future<List<Appointment>> getConflicting(
    DateTime start,
    int durationMinutes, {
    String? excludeId,
  }) async {
    final db = await _db.database;
    final startMs = start.millisecondsSinceEpoch;
    final endMs = start
        .add(Duration(minutes: durationMinutes))
        .millisecondsSinceEpoch;

    String where =
        "status IN (?, ?) AND date_time < ? AND (date_time + duration_minutes * 60000) > ?";
    final List<dynamic> args = [
      AppointmentStatus.scheduled.name,
      AppointmentStatus.confirmed.name,
      endMs,
      startMs,
    ];

    if (excludeId != null) {
      where += ' AND id != ?';
      args.add(excludeId);
    }

    final maps = await db.query('appointments', where: where, whereArgs: args);
    return maps.map(Appointment.fromMap).toList();
  }

  Future<void> save(Appointment appointment) async {
    final db = await _db.database;
    await db.insert('appointments', appointment.toMap());
  }

  Future<void> update(Appointment appointment) async {
    final db = await _db.database;
    await db.update(
      'appointments',
      appointment.toMap(),
      where: 'id = ?',
      whereArgs: [appointment.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('appointments', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Appointment>> getFutureByCustomer(String customerId) async {
    final db = await _db.database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final maps = await db.query(
      'appointments',
      where: 'customer_id = ? AND date_time > ? AND status IN (?, ?)',
      whereArgs: [
        customerId,
        nowMs,
        AppointmentStatus.scheduled.name,
        AppointmentStatus.confirmed.name,
      ],
    );
    return maps.map(Appointment.fromMap).toList();
  }

  Future<void> deleteFutureByCustomer(String customerId) async {
    final db = await _db.database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await db.delete(
      'appointments',
      where: 'customer_id = ? AND date_time > ? AND status IN (?, ?)',
      whereArgs: [
        customerId,
        nowMs,
        AppointmentStatus.scheduled.name,
        AppointmentStatus.confirmed.name,
      ],
    );
  }
}
