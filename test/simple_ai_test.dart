import 'package:flutter_test/flutter_test.dart';
import 'package:poka_fugou_app/models/ai/simple_ai.dart';

import 'helpers/test_cards.dart';

void main() {
  final ai = SimpleAI();

  test('ワンペアはペア以外の3枚を捨てる', () {
    expect(ai.decideDiscards(hand(['9/S', '9/H', '4/C', 'K/C', '2/D'])), {
      2,
      3,
      4,
    });
  });
  test('ツーペアは残りの1枚を捨てる', () {
    expect(ai.decideDiscards(hand(['9/S', '9/H', '4/C', '4/D', '2/D'])), {4});
  });
  test('スリーカードは残りの2枚を捨てる', () {
    expect(ai.decideDiscards(hand(['9/S', '9/H', '9/C', '4/D', '2/D'])), {
      3,
      4,
    });
  });
  test('役なしはAを残して4枚捨てる', () {
    expect(ai.decideDiscards(hand(['3/S', 'A/H', '9/C', '4/D', '2/D'])), {
      0,
      2,
      3,
      4,
    });
  });
  test('フラッシュは捨てない', () {
    expect(
      ai.decideDiscards(hand(['3/S', 'A/S', '9/S', '4/S', '2/S'])),
      isEmpty,
    );
  });
  test('ジョーカーは絶対に捨てない', () {
    expect(ai.decideDiscards(hand(['9/S', '9/H', 'JOKER/B', '3/C', '2/D'])), {
      3,
      4,
    });
    final discards = ai.decideDiscards(
      hand(['JOKER/B', '3/S', '5/H', '8/C', 'K/D']),
    );
    expect(discards.contains(0), isFalse);
  });
}
