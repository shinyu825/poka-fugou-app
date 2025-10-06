import 'package:poka_fugou_app/constants/hand_rank.dart';

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

  @override
  String toString() {
    return 'HandScore(役: ${rank.jpName}, キッカー: $tiebreakers)';
  }
}
