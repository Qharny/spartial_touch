import 'package:shared_preferences/shared_preferences.dart';

/// Performance mode controlling camera FPS and gesture cooldown.
enum PerformanceMode { batterySaver, balanced, performance }

extension PerformanceModeX on PerformanceMode {
  String get label => switch (this) {
        PerformanceMode.batterySaver => 'Battery Saver',
        PerformanceMode.balanced     => 'Balanced',
        PerformanceMode.performance  => 'Performance',
      };

  String get description => switch (this) {
        PerformanceMode.batterySaver => '5 FPS · 2000 ms cooldown\nMaximum battery saving',
        PerformanceMode.balanced     => '15 FPS · 800 ms cooldown\nRecommended for everyday use',
        PerformanceMode.performance  => '30 FPS · 300 ms cooldown\nFastest response, higher battery use',
      };

  /// Camera frames per second for this mode
  int get fps => switch (this) {
        PerformanceMode.batterySaver => 5,
        PerformanceMode.balanced     => 15,
        PerformanceMode.performance  => 30,
      };

  /// Gesture cooldown in milliseconds for this mode
  int get cooldownMs => switch (this) {
        PerformanceMode.batterySaver => 2000,
        PerformanceMode.balanced     => 800,
        PerformanceMode.performance  => 300,
      };

  String get _key => name;
}

/// Persists and loads [PerformanceMode] from SharedPreferences.
class PerformanceModeService {
  static const _prefKey = 'performance_mode';

  static Future<PerformanceMode> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefKey);
    return PerformanceMode.values.firstWhere(
      (m) => m.name == stored,
      orElse: () => PerformanceMode.balanced,
    );
  }

  static Future<void> save(PerformanceMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, mode.name);
  }
}
