/// In-memory session state (UI-only — resets on a full app restart).
///
/// Used by the Splash → fork: a brand-new launch routes into onboarding,
/// while a session that has already finished onboarding goes straight to the
/// Dashboard. Swap this for persisted storage (e.g. SharedPreferences) when
/// wiring real app functionality.
class AppSession {
  AppSession._();

  /// Single shared instance.
  static final AppSession instance = AppSession._();

  /// True once the onboarding funnel has been completed (or skipped).
  bool onboardingComplete = false;
}
