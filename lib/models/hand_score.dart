import 'package:poka_fugou_app/constants/hand_rank.dart';

/// ポーカー役表示
class HandScore implements Comparable<HandScore> {
  final HandRank rank;
  final List<int> tiebreakers;

  const HandScore(this.rank, this.tiebreakers);

  @override
  int compareTo(HandScore other) {
    if (rank.index != other.rank.index) {
      return rank.index.compareTo(other.rank.index);
    }
    for (int i = 0; i < tiebreakers.length; i++) {
      if (tiebreakers[i] != other.tiebreakers[i]) {
        return tiebreakers[i].compareTo(other.tiebreakers[i]);
      }
    }
    return 0;
  }

  /// 役名 + 詳細（例: ワンペア(9)、ツーペア(K・9)、フルハウス(Q・3)）
  String get jpNameWithDetail {
    final detail = _detailRanks.map(_rankLabel).join('・');
    return detail.isEmpty ? rank.jpName : '${rank.jpName}($detail)';
  }

  /// 詳細に表示するランク
  List<int> get _detailRanks {
    switch (rank) {
      case HandRank.twoPair:
      case HandRank.fullHouse:
        return tiebreakers.take(2).toList();
      case HandRank.royalFlush:
        return [];
      default:
        return tiebreakers.take(1).toList();
    }
  }

  static String _rankLabel(int rank) {
    switch (rank) {
      case 14:
        return 'A';
      case 13:
        return 'K';
      case 12:
        return 'Q';
      case 11:
        return 'J';
      default:
        return '$rank';
    }
  }

  @override
  String toString() {
    return 'HandScore(役: ${rank.jpName}, キッカー: $tiebreakers)';
  }
}
