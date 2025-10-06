class CreateDeckResponse {
  final bool success;
  final String deckId;
  final bool shuffled;
  final int remaining;
  CreateDeckResponse({
    required this.success,
    required this.deckId,
    required this.shuffled,
    required this.remaining,
  });

  factory CreateDeckResponse.fromJson(Map<String, dynamic> json) =>
      CreateDeckResponse(
        success: json['success'] as bool,
        deckId: json['deck_id'] as String,
        shuffled: json['shuffled'] as bool,
        remaining: json['remaining'] as int,
      );
}
