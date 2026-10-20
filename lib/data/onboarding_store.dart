import 'package:shared_preferences/shared_preferences.dart';

class OnboardingStore {
  static const _doneKey = 'onboarding_done_v1';

  Future<bool> isDone() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_doneKey) ?? false;
  }

  Future<void> markDone() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_doneKey, true);
  }
}
