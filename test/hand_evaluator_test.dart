import 'package:flutter_test/flutter_test.dart';
import 'package:poka_fugou_app/constants/hand_rank.dart';
import 'package:poka_fugou_app/models/hand_evaluator.dart';

import 'helpers/test_cards.dart';

void main() {
  HandRank rankOf(List<String> codes) =>
      HandEvaluator.evaluate5(hand(codes)).rank;
  String detailOf(List<String> codes) =>
      HandEvaluator.evaluate5(hand(codes)).jpNameWithDetail;

  group('役判定', () {
    test('ハイカード', () {
      expect(rankOf(['3/S', 'A/H', '9/C', '4/D', '2/C']), HandRank.highCard);
    });
    test('ワンペア', () {
      expect(rankOf(['9/S', '9/H', '4/C', 'K/C', '2/D']), HandRank.onePair);
    });
    test('ツーペア', () {
      expect(rankOf(['9/S', '9/H', 'K/C', 'K/D', '2/D']), HandRank.twoPair);
    });
    test('スリーカード', () {
      expect(rankOf(['9/S', '9/H', '9/C', '4/D', '2/D']), HandRank.threeKind);
    });
    test('ストレート（10を含む）', () {
      expect(rankOf(['6/S', '10/H', '8/C', '9/C', '7/D']), HandRank.straight);
    });
    test('ストレート（A-2-3-4-5）', () {
      expect(rankOf(['3/S', 'A/H', '5/S', '4/C', '2/S']), HandRank.straight);
    });
    test('フラッシュ', () {
      expect(rankOf(['3/S', 'A/S', '9/S', '4/S', '2/S']), HandRank.flush);
    });
    test('フルハウス', () {
      expect(rankOf(['Q/S', 'Q/H', 'Q/C', '3/D', '3/C']), HandRank.fullHouse);
    });
    test('フォーカード', () {
      expect(rankOf(['7/S', '7/H', '7/C', '7/D', '2/C']), HandRank.fourKind);
    });
    test('ストレートフラッシュ', () {
      expect(
        rankOf(['5/S', '6/S', '7/S', '8/S', '9/S']),
        HandRank.straightFlush,
      );
    });
    test('ロイヤルフラッシュ', () {
      expect(rankOf(['A/S', 'K/S', 'Q/S', 'J/S', '10/S']), HandRank.royalFlush);
    });
  });

  group('ジョーカー（ワイルドカード）', () {
    test('フォーカード + ジョーカー → ファイブカード', () {
      final score = HandEvaluator.evaluate5(
        hand(['7/S', '7/H', '7/D', '7/C', 'JOKER/B']),
      );
      expect(score.rank, HandRank.fiveKind);
      expect(score.rank.point, 10);
    });
    test('A K Q J + ジョーカー → ロイヤルフラッシュ', () {
      expect(
        rankOf(['A/S', 'K/S', 'Q/S', 'J/S', 'JOKER/B']),
        HandRank.royalFlush,
      );
    });
    test('ジョーカー2枚 + 5 9 K → Kのスリーカード', () {
      final score = HandEvaluator.evaluate5(
        hand(['JOKER/B', 'JOKER/R', '5/S', '9/H', 'K/C']),
      );
      expect(score.rank, HandRank.threeKind);
      expect(score.tiebreakers.first, 13);
    });
    test('ジョーカー入りの役と素の役は同じ強さ', () {
      final withJoker = HandEvaluator.evaluate5(
        hand(['9/S', '9/H', 'JOKER/B', '3/C', '2/D']),
      );
      final natural = HandEvaluator.evaluate5(
        hand(['9/S', '9/H', '9/C', '3/C', '2/D']),
      );
      expect(withJoker.compareTo(natural), 0);
    });
  });

  group('勝敗の比較', () {
    test('同じ役ならキッカーで決まる', () {
      final high = HandEvaluator.evaluate5(
        hand(['K/S', '10/H', '9/C', '7/D', '3/S']),
      );
      final low = HandEvaluator.evaluate5(
        hand(['K/H', '10/D', '9/S', '7/C', '2/S']),
      );
      expect(high.compareTo(low), greaterThan(0));
    });
    test('同じ数字でスート違いなら引き分け', () {
      final a = HandEvaluator.evaluate5(
        hand(['9/S', '9/H', 'K/C', '3/D', '2/S']),
      );
      final b = HandEvaluator.evaluate5(
        hand(['9/D', '9/C', 'K/S', '3/C', '2/H']),
      );
      expect(a.compareTo(b), 0);
    });
    test('渡した手札の並び順を変えない', () {
      final cards = hand(['9/S', '2/H', 'A/C', 'K/C', '4/D']);
      HandEvaluator.evaluate5(cards);
      expect(cards.map((c) => c.value).toList(), [
        '9',
        '2',
        'ACE',
        'KING',
        '4',
      ]);
    });
  });

  group('役の詳細表示', () {
    test('ワンペア(9)', () {
      expect(detailOf(['9/S', '9/H', '4/C', 'K/C', '2/D']), 'ワンペア(9)');
    });
    test('ツーペア(K・9)', () {
      expect(detailOf(['9/S', '9/H', 'K/C', 'K/D', '2/D']), 'ツーペア(K・9)');
    });
    test('フルハウス(Q・3)', () {
      expect(detailOf(['Q/S', 'Q/H', 'Q/C', '3/D', '3/C']), 'フルハウス(Q・3)');
    });
    test('ストレートは一番強いカード', () {
      expect(detailOf(['6/S', '7/H', '8/C', '9/D', '10/C']), 'ストレート(10)');
      expect(detailOf(['A/S', '2/H', '3/C', '4/D', '5/C']), 'ストレート(5)');
    });
    test('ハイカード(A)', () {
      expect(detailOf(['3/S', 'A/H', '9/C', '4/D', '2/C']), 'ハイカード(A)');
    });
    test('ロイヤルフラッシュは詳細なし', () {
      expect(detailOf(['A/S', 'K/S', 'Q/S', 'J/S', '10/S']), 'ロイヤルフラッシュ');
    });
  });

  group('役のポイント', () {
    test('役なしは1、以降は強さ順に+1、ファイブカードは10', () {
      expect(HandRank.highCard.point, 1);
      expect(HandRank.onePair.point, 1);
      expect(HandRank.twoPair.point, 2);
      expect(HandRank.royalFlush.point, 9);
      expect(HandRank.fiveKind.point, 10);
    });
  });
}
