import 'package:poka_fugou_app/models/api/create_deck_response.dart';
import 'package:poka_fugou_app/models/api/draw_response.dart';
import 'package:poka_fugou_app/models/api/playing_card.dart';
import 'package:poka_fugou_app/repository/api_connection.dart';
import 'package:poka_fugou_app/repository/repuest/draw_deck_request.dart';
import 'package:poka_fugou_app/repository/repuest/return_cards_request.dart';
import 'package:poka_fugou_app/repository/repuest/shuffle_deck_request.dart';
import 'package:poka_fugou_app/repository/request_interface.dart';

/// テスト用の通信（山札の代わりに[deck]から順に配る。[failAfter]回目以降は失敗する）
///
/// 山札に戻す・シャッフルにも対応する（戻したカードは[returnPool]から[deck]の末尾に足す）
class FakeApiClient implements ApiClient {
  final List<PlayingCard> deck;
  final int? failAfter;
  int requestCount = 0;

  /// 戻せるカード（コードで探す。捨て札として記録したカードを渡しておく）
  final List<PlayingCard> returnPool;

  /// 戻したカードのコード
  final List<String> returnedCodes = [];

  FakeApiClient({
    required this.deck,
    this.failAfter,
    this.returnPool = const [],
  });

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
    if (request is ReturnCardsRequest) {
      final returnRequest = request as ReturnCardsRequest;
      returnedCodes.addAll(returnRequest.codes);
      deck.addAll(
        returnPool.where((c) => returnRequest.codes.contains(c.code)),
      );
      return ApiResult.success(_deckResponse(returnRequest.deckId) as T);
    }
    if (request is ShuffleDeckRequest) {
      final shuffleRequest = request as ShuffleDeckRequest;
      return ApiResult.success(_deckResponse(shuffleRequest.deckId) as T);
    }
    throw UnimplementedError('未対応のリクエスト: ${request.segment}');
  }

  CreateDeckResponse _deckResponse(String deckId) => CreateDeckResponse(
    success: true,
    deckId: deckId,
    shuffled: true,
    remaining: deck.length,
  );
}
