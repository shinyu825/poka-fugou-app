import 'dart:math';

import 'package:poka_fugou_app/constants/hand_rank.dart';
import 'package:poka_fugou_app/models/api/playing_card.dart';
import 'package:poka_fugou_app/models/hand_evaluator.dart';
import 'package:poka_fugou_app/models/hand_score.dart';

/// 強化版AI
class MonteCarloAI {
  final int simulations;
  final Random rng;
  MonteCarloAI({this.simulations = 1000, Random? rng}) : rng = rng ?? Random();

  Set<int> decideDiscards(
    List<PlayingCard> hand,
    List<PlayingCard> deckRemaining,
  ) {
    Set<int> bestDiscard = {};
    int bestScore = -1;

    for (final discard in _allDiscards(hand.length)) {
      int acc = 0;
      for (int s = 0; s < simulations; s++) {
        // 山札をシャッフルコピーして、discard枚数だけ引く
        final pool = List<PlayingCard>.from(deckRemaining)..shuffle(rng);
        final draw = pool.take(discard.length).toList();
        final newHand = <PlayingCard>[];
        int di = 0;
        for (int i = 0; i < hand.length; i++) {
          if (discard.contains(i)) {
            newHand.add(draw[di++]);
          } else {
            newHand.add(hand[i]);
          }
        }
        final sc = HandEvaluator.evaluate5(newHand);
        acc += _scoreValue(sc); // 役の強さ→整数化
      }
      final avg = acc ~/ simulations;
      if (avg > bestScore) {
        bestScore = avg;
        bestDiscard = discard;
      }
    }
    return bestDiscard;
  }

  Iterable<Set<int>> _allDiscards(int n) sync* {
    for (int mask = 0; mask < (1 << n); mask++) {
      final set = <int>{};
      for (int i = 0; i < n; i++) {
        if ((mask & (1 << i)) != 0) set.add(i);
      }
      yield set;
    }
  }

  int _scoreValue(HandScore s) {
    // 粗い重み付け（必要に応じて調整）
    const base = {
      HandRank.highCard: 1,
      HandRank.onePair: 2,
      HandRank.twoPair: 3,
      HandRank.threeKind: 4,
      HandRank.straight: 5,
      HandRank.flush: 6,
      HandRank.fullHouse: 7,
      HandRank.fourKind: 8,
      HandRank.straightFlush: 9,
      HandRank.royalFlush: 10,
    };
    // キッカーも少し加点
    int kicker = 0;
    for (int i = 0; i < s.tiebreakers.length; i++) {
      kicker = kicker * 15 + s.tiebreakers[i]; // 2..14
    }
    return base[s.rank]! * 100000 + kicker;
  }
}
