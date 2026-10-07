import 'package:poka_fugou_app/constants/strings.dart';

/// 難易度
enum Difficulty {
  easy,
  hard;

  /// 日本語表記を返す
  String get jpName {
    switch (this) {
      case Difficulty.easy:
        return AppStrings.easy;
      case Difficulty.hard:
        return AppStrings.hard;
    }
  }
}
