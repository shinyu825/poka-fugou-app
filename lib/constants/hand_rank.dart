/// ポーカー役
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
  royalFlush,
  fiveKind;

  /// 勝ったときに得られるポイント（役なしは1、以降は強さ順に+1）
  int get point => this == HandRank.highCard ? 1 : index;

  /// 日本語表記を返す
  String get jpName {
    switch (this) {
      case HandRank.highCard:
        return 'ハイカード';
      case HandRank.onePair:
        return 'ワンペア';
      case HandRank.twoPair:
        return 'ツーペア';
      case HandRank.threeKind:
        return 'スリーカード';
      case HandRank.straight:
        return 'ストレート';
      case HandRank.flush:
        return 'フラッシュ';
      case HandRank.fullHouse:
        return 'フルハウス';
      case HandRank.fourKind:
        return 'フォーカード';
      case HandRank.straightFlush:
        return 'ストレートフラッシュ';
      case HandRank.royalFlush:
        return 'ロイヤルフラッシュ';
      case HandRank.fiveKind:
        return 'ファイブカード';
    }
  }
}
