import 'package:shared_preferences/shared_preferences.dart';

/// Persisted session state, backed by [SharedPreferences].
///
/// The Splash screen forks on [onboardingComplete]: a fresh install routes
/// into the onboarding funnel, while a user who has already finished it goes
/// straight to the Dashboard — and that choice now survives app restarts.
class AppSession {
  AppSession._();

  /// Single shared instance.
  static final AppSession instance = AppSession._();

  static const String _kOnboardingComplete = 'onboarding_complete';

  bool _onboardingComplete = false;

  /// Whether the onboarding funnel has been completed (or skipped).
  /// Reflects the last [load] / [setOnboardingComplete] call.
  bool get onboardingComplete => _onboardingComplete;

  /// Hydrate the in-memory flags from disk. Call once before reading state
  /// (the Splash screen does this during its delay).
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _onboardingComplete = prefs.getBool(_kOnboardingComplete) ?? false;
  }

  /// Persist the onboarding-complete flag.
  Future<void> setOnboardingComplete(bool value) async {
    _onboardingComplete = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingComplete, value);
  }
}
