import 'package:poka_fugou_app/constants/hand_rank.dart';
import 'package:poka_fugou_app/models/api/playing_card.dart';
import 'package:poka_fugou_app/models/hand_score.dart';

class HandEvaluator {
  // 役判定（AはストレートでA,2,3,4,5も許容）
  static evaluate5(List<PlayingCard> hand) {
    hand.sort((a, b) => b.value.compareTo(a.value));
    final ranks = hand.map((c) => c.value).toList();
    final suits = hand.map((c) => c.suit).toList();

    bool isFlush = suits.toSet().length == 1;

    bool isStraight = () {
      var r = List<int>.from(ranks);
      // A-2-3-4-5対応
      if (ranks.toSet().containsAll({14, 2, 3, 4, 5})) {
        return true;
      }
      for (int i = 0; i < 4; i++) {
        if (r[i] - 1 != r[i + 1]) return false;
      }
      return true;
    }();

    // 役の頻度テーブル
    final count = <int, int>{};
    for (var r in ranks) {
      count[r] = (count[r] ?? 0) + 1;
    }
    final groups = count.entries.toList()
      ..sort((a, b) {
        // 枚数で降順、同数ならランク降順
        int c = b.value.compareTo(a.value);
        if (c != 0) return c;
        return b.key.compareTo(a.key);
      });

    if (isStraight && isFlush) {
      final top = (ranks[0] == 14 && ranks[1] == 13)
          ? HandRank.royalFlush
          : HandRank.straightFlush;
      return HandScore(top, [ranks[0] == 14 && ranks[1] == 5 ? 5 : ranks[0]]);
    }

    if (groups[0].value == 4) {
      // フォーカード
      return HandScore(HandRank.fourKind, [groups[0].key, groups[1].key]);
    }
    if (groups[0].value == 3 && groups[1].value == 2) {
      // フルハウス
      return HandScore(HandRank.fullHouse, [groups[0].key, groups[1].key]);
    }
    if (isFlush) {
      return HandScore(HandRank.flush, ranks);
    }
    if (isStraight) {
      return HandScore(HandRank.straight, [
        ranks[0] == 14 && ranks[1] == 5 ? 5 : ranks[0],
      ]);
    }
    if (groups[0].value == 3) {
      // 3枚のランク + 残りキッカー降順
      final kickers = groups.skip(1).map((e) => e.key).toList()
        ..sort((a, b) => b.compareTo(a));
      return HandScore(HandRank.threeKind, [groups[0].key, ...kickers]);
    }
    if (groups[0].value == 2 && groups[1].value == 2) {
      final pairHigh = groups[0].key, pairLow = groups[1].key;
      final kicker = groups[2].key;
      return HandScore(HandRank.twoPair, [pairHigh, pairLow, kicker]);
    }
    if (groups[0].value == 2) {
      final kickers = groups.skip(1).map((e) => e.key).toList()
        ..sort((a, b) => b.compareTo(a));
      return HandScore(HandRank.onePair, [groups[0].key, ...kickers]);
    }
    return HandScore(HandRank.highCard, ranks);
  }
}
