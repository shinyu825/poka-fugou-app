import 'package:poka_fugou_app/constants/hand_rank.dart';
import 'package:poka_fugou_app/models/api/card_images.dart';
import 'package:poka_fugou_app/models/api/playing_card.dart';
import 'package:poka_fugou_app/models/hand_score.dart';

/// 役判定
class HandEvaluator {
  static const _values = [
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
    'JACK',
    'QUEEN',
    'KING',
    'ACE',
  ];
  static const _suits = ['SPADES', 'HEARTS', 'DIAMONDS', 'CLUBS'];

  /// ジョーカーの置き換え候補（52種類）
  static final List<PlayingCard> _allCards = [
    for (final suit in _suits)
      for (final value in _values)
        PlayingCard(
          code: '',
          image: '',
          images: CardImages(svg: '', png: ''),
          value: value,
          suit: suit,
        ),
  ];

  /// 役判定（ジョーカーは一番強くなるカードとして扱う）
  static HandScore evaluate5(List<PlayingCard> hand) {
    return _best(hand).score;
  }

  /// ジョーカーを一番強くなるカードに置き換えた手札を返す（並び順は元のまま）
  static List<PlayingCard> resolveJokers(List<PlayingCard> hand) {
    return _best(hand).hand;
  }

  static ({HandScore score, List<PlayingCard> hand}) _best(
    List<PlayingCard> hand,
  ) {
    final jokerIndexes = [
      for (int i = 0; i < hand.length; i++)
        if (hand[i].isJoker) i,
    ];
    if (jokerIndexes.isEmpty) {
      return (score: _evaluate(hand), hand: hand);
    }

    HandScore? bestScore;
    List<PlayingCard> bestHand = hand;
    for (final substitutes in _substitutions(jokerIndexes.length)) {
      final candidate = [...hand];
      for (int i = 0; i < jokerIndexes.length; i++) {
        candidate[jokerIndexes[i]] = substitutes[i];
      }
      final score = _evaluate(candidate);
      if (bestScore == null || score.compareTo(bestScore) > 0) {
        bestScore = score;
        bestHand = candidate;
      }
    }
    return (score: bestScore!, hand: bestHand);
  }

  /// ジョーカーの置き換えの全組み合わせ（2枚のときは順不同）
  static Iterable<List<PlayingCard>> _substitutions(int jokerCount) sync* {
    if (jokerCount == 1) {
      for (final card in _allCards) {
        yield [card];
      }
      return;
    }
    for (int i = 0; i < _allCards.length; i++) {
      for (int j = i; j < _allCards.length; j++) {
        yield [_allCards[i], _allCards[j]];
      }
    }
  }

  /// 役判定（ジョーカーなし。AはストレートでA,2,3,4,5も許容）
  static HandScore _evaluate(List<PlayingCard> hand) {
    final sorted = [...hand]
      ..sort(
        (a, b) => parsePorkerRank(b.value).compareTo(parsePorkerRank(a.value)),
      );
    final ranks = sorted.map((c) => parsePorkerRank(c.value)).toList();
    final suits = sorted.map((c) => c.suit).toList();

    final bool isFlush = suits.toSet().length == 1;

    final bool isStraight = () {
      final r = List<int>.from(ranks);
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
    for (final r in ranks) {
      count[r] = (count[r] ?? 0) + 1;
    }
    final groups = count.entries.toList()
      ..sort((a, b) {
        // 枚数で降順、同数ならランク降順
        final int c = b.value.compareTo(a.value);
        if (c != 0) return c;
        return b.key.compareTo(a.key);
      });

    if (groups[0].value == 5) {
      // ファイブカード（ジョーカー込みのみ成立）
      return HandScore(HandRank.fiveKind, [groups[0].key]);
    }

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
