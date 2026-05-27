import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer.dart';
import '../repositories/customer_repository.dart';
import '../repositories/appointment_repository.dart';
import 'appointments_notifier.dart';

class CustomersNotifier extends StateNotifier<AsyncValue<List<Customer>>> {
  final CustomerRepository _repository;
  final AppointmentRepository _appointmentRepository;
  final AppointmentsNotifier _appointmentsNotifier;

  CustomersNotifier(
      this._repository, this._appointmentRepository, this._appointmentsNotifier)
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

  Future<void> addCustomer(Customer customer) async {
    await _repository.save(customer);
    await loadAll();
  }

  Future<void> updateCustomer(Customer customer) async {
    await _repository.update(customer);
    await loadAll();
  }

  Future<void> deleteCustomer(String id, {bool deleteFutureAppointments = false}) async {
    if (deleteFutureAppointments) {
      await _appointmentRepository.deleteFutureByCustomer(id);
      await _appointmentsNotifier.loadAll();
    }
    await _repository.delete(id);
    await loadAll();
  }

  Future<void> bulkAddCustomers(List<Customer> customers) async {
    for (final c in customers) {
      await _repository.save(c);
    }
    await loadAll();
  }
}
