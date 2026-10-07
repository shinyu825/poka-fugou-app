import 'package:poka_fugou_app/models/api/playing_card.dart';

/// ゲーム全体の状態（変更は copyWith で新しい状態を作る）
class GameState {
  /// 使用中のデッキID
  final String deckId;

  /// 自分の手札
  final List<PlayingCard> myCards;

  /// 相手1の手札
  final List<PlayingCard> cards1;

  /// 山札の残り枚数
  final int remaining;

  /// ポーカーで手放したカード（山札が尽きたときに山札へ戻す候補）
  final List<PlayingCard> discardedCards;

  /// 累計ポイント（自分・相手1）
  final int myPoint;
  final int point1;

  const GameState({
    this.deckId = '',
    this.myCards = const [],
    this.cards1 = const [],
    this.remaining = 0,
    this.discardedCards = const [],
    this.myPoint = 0,
    this.point1 = 0,
  });

  GameState copyWith({
    String? deckId,
    List<PlayingCard>? myCards,
    List<PlayingCard>? cards1,
    int? remaining,
    List<PlayingCard>? discardedCards,
    int? myPoint,
    int? point1,
  }) {
    return GameState(
      deckId: deckId ?? this.deckId,
      myCards: myCards ?? this.myCards,
      cards1: cards1 ?? this.cards1,
      remaining: remaining ?? this.remaining,
      discardedCards: discardedCards ?? this.discardedCards,
      myPoint: myPoint ?? this.myPoint,
      point1: point1 ?? this.point1,
    );
  }
}
