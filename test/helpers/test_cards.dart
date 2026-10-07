import 'package:poka_fugou_app/models/api/card_images.dart';
import 'package:poka_fugou_app/models/api/playing_card.dart';

/// テスト用のカード生成（画像などは空）
PlayingCard card(String value, [String suit = 'SPADES']) => PlayingCard(
  code: '',
  image: '',
  images: CardImages(svg: '', png: ''),
  value: value,
  suit: suit,
);

/// テスト用のジョーカー
PlayingCard joker([String suit = 'BLACK']) => card('JOKER', suit);

/// 「値/スート」の短い表記からカードを作る（例: 'A/S', '10/H', 'JOKER/B'）
///
/// スートは S=SPADES, H=HEARTS, D=DIAMONDS, C=CLUBS, B=BLACK, R=RED
List<PlayingCard> hand(List<String> codes) {
  const suits = {
    'S': 'SPADES',
    'H': 'HEARTS',
    'D': 'DIAMONDS',
    'C': 'CLUBS',
    'B': 'BLACK',
    'R': 'RED',
  };
  const values = {'A': 'ACE', 'K': 'KING', 'Q': 'QUEEN', 'J': 'JACK'};
  return [
    for (final code in codes)
      () {
        final parts = code.split('/');
        return card(values[parts[0]] ?? parts[0], suits[parts[1]]!);
      }(),
  ];
}
