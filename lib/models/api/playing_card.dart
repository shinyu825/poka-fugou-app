import 'package:poka_fugou_app/models/api/card_images.dart';

class PlayingCard {
  final String code;
  final String image;
  final CardImages images;
  final int value;
  final String suit;

  PlayingCard({
    required this.code,
    required this.image,
    required this.images,
    required this.value,
    required this.suit,
  });

  factory PlayingCard.fromJson(Map<String, dynamic> json) => PlayingCard(
    code: json['code'] as String,
    image: json['image'] as String,
    images: CardImages.fromJson(
      Map<String, dynamic>.from(json['images'] as Map),
    ),
    value: parseRank(json['value'] as String),
    suit: json['suit'] as String,
  );

  // Stringのvalueをintに変更
  static List<int> toRankList(List<String> values) {
    return values.map((value) => parseRank(value)).toList();
  }

  // ランク順にソートし、ペアやスリーカードなどの重複するランクのカードを先頭に持ってくる
  static List<PlayingCard> toParseRank(List<PlayingCard> pcList) {
    // ランクごとの出現回数を数える
    final countMap = <int, int>{};
    for (var c in pcList) {
      countMap[c.value] = (countMap[c.value] ?? 0) + 1;
    }

    // 新しいリストにコピーしてソート
    final sorted = [...pcList];
    sorted.sort((a, b) {
      final countA = countMap[a.value]!;
      final countB = countMap[b.value]!;
      if (countA != countB) return countB.compareTo(countA);
      return b.value.compareTo(a.value);
    });
    return sorted;
  }
}

int parseRank(String value) {
  switch (value) {
    case "ACE":
      return 14;
    case "KING":
      return 13;
    case "QUEEN":
      return 12;
    case "JACK":
      return 11;
    default:
      return int.tryParse(value) ?? 0;
  }
}

int parseSuit(String suit) {
  switch (suit) {
    case "SPADES":
      return 0;
    case "HEARTS":
      return 1;
    case "DIAMONDS":
      return 2;
    case "CLUBS":
      return 3;
    default:
      return -1;
  }
}
