import 'package:poka_fugou_app/constants/hand_rank.dart';
import 'package:poka_fugou_app/models/api/playing_card.dart';
import 'package:poka_fugou_app/models/hand_evaluator.dart';

// シンプルAIの意思決定（交換方針）
class SimpleAI {
  /// 返り値は捨てるカードのインデックス集合
  Set<int> decideDiscards(List<PlayingCard> hand) {
    final score = HandEvaluator.evaluate5(hand);
    // 役に応じて方針
    switch (score.rank) {
      case HandRank.straight:
      case HandRank.flush:
      case HandRank.fullHouse:
      case HandRank.fourKind:
      case HandRank.straightFlush:
      case HandRank.royalFlush:
        return {}; // キープ
      case HandRank.threeKind:
        // スリーカード以外の2枚を捨てる
        final ranks = hand.map((c) => c.value).toList();
        final tripleRank = _threeKindRank(ranks); // スリーカードのランクを取得
        return {
          for (int i = 0; i < hand.length; i++)
            if (hand[i].value != tripleRank) i,
        };
      case HandRank.twoPair:
        // ツーペア以外の1枚を捨てる
        final ranks = hand.map((c) => c.value).toList();
        final pairRanks = _twoPairRanks(ranks); // 2つのペアの値を取得
        return {
          for (int i = 0; i < hand.length; i++)
            if (!pairRanks.contains(hand[i].value)) i,
        };
      case HandRank.onePair:
        // ペア以外の3枚を捨てる
        final ranks = hand.map((c) => c.value).toList();
        final pairRank = _pairRank(ranks);
        return {
          for (int i = 0; i < hand.length; i++)
            if (hand[i].value != pairRank) i,
        };
      case HandRank.highCard:
        // A or K があれば1枚残し、他は捨てる
        int keepIdx = hand.indexWhere((c) => c.value == 14);
        if (keepIdx == -1) keepIdx = hand.indexWhere((c) => c.value == 13);
        return {
          for (int i = 0; i < hand.length; i++)
            if (i != keepIdx) i,
        };
      default:
        return {};
    }
  }

  int _pairRank(List<int> ranks) {
    final count = <int, int>{};
    for (var r in ranks) {
      count[r] = (count[r] ?? 0) + 1;
    }
    return count.entries.firstWhere((e) => e.value == 2).key;
  }

  List<int> _twoPairRanks(List<int> ranks) {
    final count = <int, int>{};
    for (var r in ranks) {
      count[r] = (count[r] ?? 0) + 1;
    }

    // value == 2 のカードランクを全部取得（ツーペアの2つ分）
    final pairs = count.entries
        .where((e) => e.value == 2)
        .map((e) => e.key)
        .toList();

    return pairs;
  }

  int _threeKindRank(List<int> ranks) {
    final count = <int, int>{};
    for (var r in ranks) {
      count[r] = (count[r] ?? 0) + 1;
    }
    // 3枚そろっているランクを探す
    return count.entries.firstWhere((e) => e.value == 3).key;
  }
}
