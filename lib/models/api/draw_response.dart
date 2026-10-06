import 'package:poka_fugou_app/models/api/playing_card.dart';

/// カードドローレスポンス
class DrawResponse {
  final bool success;
  final String deckId;
  final List<PlayingCard> cards;
  final int remaining;
  DrawResponse({
    required this.success,
    required this.deckId,
    required this.cards,
    required this.remaining,
  });

  factory DrawResponse.fromJson(Map<String, dynamic> json) => DrawResponse(
    success: json['success'] as bool,
    deckId: json['deck_id'] as String,
    cards: (json['cards'] as List)
        .map((e) => PlayingCard.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    remaining: json['remaining'] as int,
  );
}
