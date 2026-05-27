import '../models/appointment.dart';
import '../repositories/appointment_repository.dart';

class ConflictService {
  final AppointmentRepository _repository;

  ConflictService(this._repository);

  Future<List<Appointment>> findConflicts(
    DateTime start,
    int durationMinutes, {
    String? excludeId,
  }) async {
    return _repository.getConflicting(
      start,
      durationMinutes,
      excludeId: excludeId,
    );
  }
}
