import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/business.dart';
import '../repositories/business_repository.dart';

class BusinessNotifier extends StateNotifier<AsyncValue<Business>> {
  final BusinessRepository _repository;

  BusinessNotifier(this._repository) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final biz = await _repository.get();
      state = AsyncValue.data(biz);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> updateBusiness(Business business) async {
    await _repository.update(business);
    state = AsyncValue.data(business);
  }
}
