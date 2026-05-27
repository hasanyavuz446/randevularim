import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const _completedKey = 'onboarding_completed';

  final SharedPreferences _prefs;

  OnboardingService(this._prefs);

  bool get isCompleted => _prefs.getBool(_completedKey) ?? false;

  Future<void> complete() => _prefs.setBool(_completedKey, true);
}
