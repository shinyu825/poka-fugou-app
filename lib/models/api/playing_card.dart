import 'package:poka_fugou_app/models/api/card_images.dart';

/// カードレスポンス
class PlayingCard {
  final String code;
  final String image;
  final CardImages images;
  final String value;
  final String suit;

  PlayingCard({
    required this.code,
    required this.image,
    required this.images,
    required this.value,
    required this.suit,
  });

  /// ジョーカーかどうか
  bool get isJoker => value == jokerValue;

  /// 表示用の値（A, K, Q, J, 10〜2, JOKER）
  String get displayValue {
    switch (value) {
      case 'ACE':
        return 'A';
      case 'KING':
        return 'K';
      case 'QUEEN':
        return 'Q';
      case 'JACK':
        return 'J';
      default:
        return value;
    }
  }

  static const String jokerValue = 'JOKER';

  factory PlayingCard.fromJson(Map<String, dynamic> json) => PlayingCard(
    code: json['code'] as String,
    image: json['image'] as String,
    images: CardImages.fromJson(
      Map<String, dynamic>.from(json['images'] as Map),
    ),
    value: json['value'] as String,
    suit: json['suit'] as String,
  );

  /// ジョーカーを先頭に、ランク順にソートし、ペアやスリーカードなどの重複するランクのカードを先頭に持ってくる
  static List<PlayingCard> toParsePorkerRank(List<PlayingCard> pcList) {
    // ランクごとの出現回数を数える
    final countMap = <int, int>{};
    for (final c in pcList) {
      countMap[parsePorkerRank(c.value)] =
          (countMap[parsePorkerRank(c.value)] ?? 0) + 1;
    }

    // 新しいリストにコピーしてソート
    final sorted = [...pcList];
    sorted.sort((a, b) {
      if (a.isJoker != b.isJoker) return a.isJoker ? -1 : 1;
      final countA = countMap[parsePorkerRank(a.value)]!;
      final countB = countMap[parsePorkerRank(b.value)]!;
      if (countA != countB) return countB.compareTo(countA);
      return parsePorkerRank(b.value).compareTo(parsePorkerRank(a.value));
    });
    return sorted;
  }

  /// 大富豪ランク順にソート（左が弱く、右が強い）
  static List<PlayingCard> toParseDaifugoRank(List<PlayingCard> pcList) {
    // 新しいリストにコピーしてソート
    final sorted = [...pcList]
      ..sort(
        (a, b) =>
            parseDaifugoRank(a.value).compareTo(parseDaifugoRank(b.value)),
      );
    return sorted;
  }
}

int parsePorkerRank(String value) {
  switch (value) {
    case 'ACE':
      return 14;
    case 'KING':
      return 13;
    case 'QUEEN':
      return 12;
    case 'JACK':
      return 11;
    default:
      return int.tryParse(value) ?? 0;
  }
}

int parseDaifugoRank(String value) {
  switch (value) {
    case PlayingCard.jokerValue:
      return 16;
    case '2':
      return 15;
    case 'ACE':
      return 14;
    case 'KING':
      return 13;
    case 'QUEEN':
      return 12;
    case 'JACK':
      return 11;
    default:
      return int.tryParse(value) ?? 0;
  }
}

int parseSuit(String suit) {
  switch (suit) {
    case 'SPADES':
      return 0;
    case 'HEARTS':
      return 1;
    case 'DIAMONDS':
      return 2;
    case 'CLUBS':
      return 3;
    default:
      return -1;
  }
}
