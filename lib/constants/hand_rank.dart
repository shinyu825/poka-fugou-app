import 'package:poka_fugou_app/models/api/playing_card.dart';

enum HandRank {
  highCard,
  onePair,
  twoPair,
  threeKind,
  straight,
  flush,
  fullHouse,
  fourKind,
  straightFlush,
  royalFlush;

  static evaluate(List<PlayingCard> myCardList) {}

  /// 日本語表記を返す
  String get jpName {
    switch (this) {
      case HandRank.highCard:
        return "ハイカード";
      case HandRank.onePair:
        return "ワンペア";
      case HandRank.twoPair:
        return "ツーペア";
      case HandRank.threeKind:
        return "スリーカード";
      case HandRank.straight:
        return "ストレート";
      case HandRank.flush:
        return "フラッシュ";
      case HandRank.fullHouse:
        return "フルハウス";
      case HandRank.fourKind:
        return "フォーカード";
      case HandRank.straightFlush:
        return "ストレートフラッシュ";
      case HandRank.royalFlush:
        return "ロイヤルフラッシュ";
    }
  }
}
