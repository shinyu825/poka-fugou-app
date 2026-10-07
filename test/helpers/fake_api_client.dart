import 'package:poka_fugou_app/models/api/draw_response.dart';
import 'package:poka_fugou_app/models/api/playing_card.dart';
import 'package:poka_fugou_app/repository/api_connection.dart';
import 'package:poka_fugou_app/repository/repuest/draw_deck_request.dart';
import 'package:poka_fugou_app/repository/request_interface.dart';

/// テスト用の通信（山札の代わりに[deck]から順に配る。[failAfter]回目以降は失敗する）
class FakeApiClient implements ApiClient {
  final List<PlayingCard> deck;
  final int? failAfter;
  int requestCount = 0;

  FakeApiClient({required this.deck, this.failAfter});

  @override
  Future<ApiResult<T>> request<T>(RequestInterface<T> request) async {
    requestCount++;
    if (failAfter != null && requestCount > failAfter!) {
      return const ApiResult.failure('テスト用のエラー');
    }
    if (request is DrawDeckRequest) {
      final drawRequest = request as DrawDeckRequest;
      final cards = deck.take(drawRequest.cardCount).toList();
      deck.removeRange(0, cards.length);
      final response = DrawResponse(
        success: true,
        deckId: drawRequest.deckId,
        cards: cards,
        remaining: deck.length,
      );
      return ApiResult.success(response as T);
    }
    throw UnimplementedError('未対応のリクエスト: ${request.segment}');
  }
}
