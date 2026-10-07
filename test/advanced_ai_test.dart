import 'package:flutter_test/flutter_test.dart';
import 'package:poka_fugou_app/constants/hand_rank.dart';
import 'package:poka_fugou_app/models/ai/advanced_ai.dart';
import 'package:poka_fugou_app/models/hand_evaluator.dart';

import 'helpers/test_cards.dart';

void main() {
  final ai = AdvancedAI();

  test('ドロー枚数は4枚', () {
    expect(AdvancedAI.drawCount, 4);
  });
  test('9枚から最強の5枚（フルハウス）を選ぶ', () {
    final cards = hand([
      'K/S',
      'Q/H',
      'Q/C',
      '3/D',
      '2/S',
      'Q/S',
      '3/H',
      '9/C',
      'A/D',
    ]);
    final best = ai.selectBestHand(cards);
    expect(best.length, 5);
    expect(HandEvaluator.evaluate5(best).rank, HandRank.fullHouse);
    expect(best.every(cards.contains), isTrue);
  });
  test('ジョーカー2枚を活かして選ぶ', () {
    final best = ai.selectBestHand(
      hand([
        'JOKER/B',
        'JOKER/R',
        '5/S',
        '9/H',
        'K/C',
        'K/S',
        '2/H',
        '7/D',
        '4/C',
      ]),
    );
    expect(HandEvaluator.evaluate5(best).rank, HandRank.fourKind);
  });
}
