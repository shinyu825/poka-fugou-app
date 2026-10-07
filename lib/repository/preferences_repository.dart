import 'package:poka_fugou_app/constants/difficulty.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 端末保存（SharedPreferences）の読み書き
class PreferencesRepository {
  static const _difficultyKey = 'difficulty';

  Future<void> saveDifficulty(Difficulty difficulty) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_difficultyKey, difficulty.name);
  }

  Future<Difficulty> loadDifficulty() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_difficultyKey);
    return Difficulty.values.firstWhere(
      (d) => d.name == name,
      orElse: () => Difficulty.easy,
    );
  }
}
