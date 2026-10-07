import 'package:poka_fugou_app/models/api/playing_card.dart';
import 'package:poka_fugou_app/models/hand_evaluator.dart';
import 'package:poka_fugou_app/models/hand_score.dart';

/// 強化版AI
///
/// 常に4枚引いて手札を9枚にし、その中から最強の5枚を選ぶ
class AdvancedAI {
  /// 交換で引く枚数
  static const int drawCount = 4;

  /// 手札（9枚）から最強の5枚を選ぶ
  ///
  /// 返り値は選ばれた5枚。選ばれなかったカードは捨て札になる
  List<PlayingCard> selectBestHand(List<PlayingCard> cards) {
    List<PlayingCard> best = cards.take(5).toList();
    HandScore bestScore = HandEvaluator.evaluate5(best);

    for (final combination in _combinations(cards, 5)) {
      final score = HandEvaluator.evaluate5(combination);
      if (score.compareTo(bestScore) > 0) {
        best = combination;
        bestScore = score;
      }
    }
    return best;
  }

  /// [cards]から[count]枚を選ぶ全組み合わせ
  Iterable<List<PlayingCard>> _combinations(
    List<PlayingCard> cards,
    int count, [
    int start = 0,
  ]) sync* {
    if (count == 0) {
      yield [];
      return;
    }
    for (int i = start; i <= cards.length - count; i++) {
      for (final rest in _combinations(cards, count - 1, i + 1)) {
        yield [cards[i], ...rest];
      }
    }
  }
}
