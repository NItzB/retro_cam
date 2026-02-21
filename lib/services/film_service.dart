import 'package:shared_preferences/shared_preferences.dart';

class FilmService {
  static const String _filmCountKey = 'film_count';
  static const String _timerStartKey = 'development_timer_start';
  static const int _initialFilmCount = 5; // Reduced for testing
  static const int _developmentDurationSeconds = 30; // 30 seconds for testing

  Future<int> getFilmCount() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('v2_testing_wipe_1')) {
       await prefs.clear();
       await prefs.setBool('v2_testing_wipe_1', true);
       await prefs.setInt(_filmCountKey, _initialFilmCount);
    }
    return prefs.getInt(_filmCountKey) ?? _initialFilmCount;
  }

  Future<void> decrementFilmCount() async {
    final prefs = await SharedPreferences.getInstance();
    int current = prefs.getInt(_filmCountKey) ?? _initialFilmCount;
    if (current > 0) {
      await prefs.setInt(_filmCountKey, current - 1);
    }
  }

  Future<void> resetFilm() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_filmCountKey, _initialFilmCount);
    await prefs.remove(_timerStartKey);
  }

  Future<void> startDevelopmentTimer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_timerStartKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<DateTime?> getDevelopmentCompletionTime() async {
    final prefs = await SharedPreferences.getInstance();
    final startMillis = prefs.getInt(_timerStartKey);
    if (startMillis == null) return null;
    
    return DateTime.fromMillisecondsSinceEpoch(startMillis)
        .add(const Duration(seconds: _developmentDurationSeconds));
  }
  
  Future<bool> isDevelopmentComplete() async {
    final completionTime = await getDevelopmentCompletionTime();
    if (completionTime == null) return false;
    return DateTime.now().isAfter(completionTime);
  }

  // Debug methods
  Future<void> debugSetFilmCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_filmCountKey, count);
  }

  Future<void> debugForceCompleteDevelopment() async {
    final prefs = await SharedPreferences.getInstance();
    // Set start time to 25 hours ago
    await prefs.setInt(_timerStartKey, DateTime.now().subtract(const Duration(hours: 25)).millisecondsSinceEpoch);
  }
}
