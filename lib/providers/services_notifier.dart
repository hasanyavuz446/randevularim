import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/service.dart';
import '../repositories/service_repository.dart';

class ServicesNotifier extends StateNotifier<AsyncValue<List<Service>>> {
  final ServiceRepository _repo;

  ServicesNotifier(this._repo) : super(const AsyncValue.loading()) {
    loadAll();
  }

  Future<void> loadAll() async {
    try {
      var list = await _repo.getAll();
      if (list.isEmpty) {
        await _repo.seedDefaults();
        list = await _repo.getAll();
      }
      state = AsyncValue.data(list);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> addService(Service service) async {
    await _repo.save(service);
    await loadAll();
  }

  Future<void> updateService(Service service) async {
    await _repo.update(service);
    await loadAll();
  }

  Future<void> deleteService(String id) async {
    await _repo.delete(id);
    await loadAll();
  }

  Future<void> reorder(List<Service> reordered) async {
    await _repo.reorderAll(reordered);
    state = AsyncValue.data(reordered);
  }
}
