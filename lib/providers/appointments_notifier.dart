import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/appointment.dart';
import '../models/app_settings.dart';
import '../models/enums.dart';
import '../repositories/appointment_repository.dart';
import '../services/notification_service.dart';

class AppointmentsNotifier
    extends StateNotifier<AsyncValue<List<Appointment>>> {
  final AppointmentRepository _repository;
  final NotificationService _notifications;

  AppointmentsNotifier(this._repository, this._notifications)
    : super(const AsyncValue.loading()) {
    loadAll();
  }

  Future<void> loadAll() async {
    try {
      final list = await _repository.getAll();
      state = AsyncValue.data(list);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> addAppointment(
    Appointment appointment,
    AppSettings settings,
  ) async {
    try {
      await _repository.save(appointment);
      await _notifications.scheduleForAppointment(appointment, settings);
      await loadAll();
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> addAppointments(
    List<Appointment> appointments,
    AppSettings settings,
  ) async {
    try {
      for (final appointment in appointments) {
        await _repository.save(appointment);
        await _notifications.scheduleForAppointment(appointment, settings);
      }
      await loadAll();
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> updateAppointment(
    Appointment appointment,
    AppSettings settings,
  ) async {
    try {
      await _notifications.cancelForAppointment(appointment.id);
      await _repository.update(appointment);
      if (appointment.isActive) {
        await _notifications.scheduleForAppointment(appointment, settings);
      }
      await loadAll();
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> cancelAppointment(String id) async {
    final list = state.value;
    if (list == null) return;
    final appt = list.firstWhere((a) => a.id == id);
    await _notifications.cancelForAppointment(id);
    await _repository.update(
      appt.copyWith(status: AppointmentStatus.cancelled),
    );
    await loadAll();
  }

  Future<void> completeAppointment(String id) async {
    final list = state.value;
    if (list == null) return;
    final appt = list.firstWhere((a) => a.id == id);
    await _notifications.cancelForAppointment(id);
    await _repository.update(
      appt.copyWith(status: AppointmentStatus.completed),
    );
    await loadAll();
  }

  Future<void> confirmAppointment(String id) async {
    final list = state.value;
    if (list == null) return;
    final appt = list.firstWhere((a) => a.id == id);
    await _repository.update(
      appt.copyWith(status: AppointmentStatus.confirmed),
    );
    await loadAll();
  }

  Future<void> markNoShow(String id) async {
    final list = state.value;
    if (list == null) return;
    final appt = list.firstWhere((a) => a.id == id);
    await _notifications.cancelForAppointment(id);
    await _repository.update(appt.copyWith(status: AppointmentStatus.noShow));
    await loadAll();
  }
}
