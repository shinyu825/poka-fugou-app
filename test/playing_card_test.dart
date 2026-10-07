import 'package:flutter_test/flutter_test.dart';
import 'package:poka_fugou_app/models/api/playing_card.dart';

import 'helpers/test_cards.dart';

void main() {
  group('ポーカーの並び順', () {
    test('ペアを先頭に、数値として大きい順', () {
      final sorted = PlayingCard.toParsePorkerRank(
        hand(['2/S', '2/H', '9/C', '3/C', '10/D']),
      );
      expect(sorted.map((c) => c.value).toList(), ['2', '2', '10', '9', '3']);
    });
    test('ジョーカーが先頭', () {
      final sorted = PlayingCard.toParsePorkerRank(
        hand(['9/S', 'JOKER/B', '3/C', '9/H', '2/D']),
      );
      expect(sorted.map((c) => c.value).toList(), [
        'JOKER',
        '9',
        '9',
        '3',
        '2',
      ]);
    });
  });

  group('大富豪の並び順', () {
    test('左が弱く右が強い。2の次にジョーカー', () {
      final sorted = PlayingCard.toParseDaifugoRank(
        hand(['2/S', '5/S', 'JOKER/B', 'A/S', '3/S', '10/S', 'K/S']),
      );
      expect(sorted.map((c) => c.value).toList(), [
        '3',
        '5',
        '10',
        'KING',
        'ACE',
        '2',
        'JOKER',
      ]);
    });
  });

  group('表示用の値', () {
    test('絵札は1文字、数字はそのまま', () {
      expect(card('ACE').displayValue, 'A');
      expect(card('KING').displayValue, 'K');
      expect(card('QUEEN').displayValue, 'Q');
      expect(card('JACK').displayValue, 'J');
      expect(card('10').displayValue, '10');
      expect(joker().displayValue, 'JOKER');
    });
    test('ジョーカー判定', () {
      expect(joker().isJoker, isTrue);
      expect(card('ACE').isJoker, isFalse);
    });
  });
}
