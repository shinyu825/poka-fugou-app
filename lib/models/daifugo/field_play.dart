import 'package:poka_fugou_app/models/api/playing_card.dart';
import 'package:poka_fugou_app/models/daifugo/daifugo_player.dart';

/// 場に出された 1 回分のカード
class FieldPlay {
  final List<PlayingCard> cards;
  final DaifugoPlayer player;

  /// 強さ比較に使うランク（ジョーカーだけのときは最強。数縛り中は求められていたランク）
  final int rank;

  const FieldPlay({
    required this.cards,
    required this.player,
    required this.rank,
  });

  bool get isJokerOnly => cards.every((c) => c.isJoker);
  bool get hasJoker => cards.any((c) => c.isJoker);

  /// ジョーカー以外のスート
  Set<String> get suits => {
    for (final c in cards)
      if (!c.isJoker) c.suit,
  };
}
