import 'package:poka_fugou_app/models/api/create_deck_response.dart';
import 'package:poka_fugou_app/repository/request_interface.dart';

/// 手放したカードを山札に戻すリクエスト
class ReturnCardsRequest extends RequestInterface<CreateDeckResponse> {
  final String deckId;
  final List<String> codes;
  ReturnCardsRequest({required this.deckId, required this.codes});

  @override
  String get method => 'GET';
  @override
  String get segment => '$deckId/return';
  @override
  Map<String, dynamic>? get data => {'cards': codes.join(',')};

  @override
  CreateDeckResponse parse(Map<String, dynamic> json) =>
      CreateDeckResponse.fromJson(json);
}
