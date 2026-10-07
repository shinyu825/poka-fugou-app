import 'package:poka_fugou_app/models/api/draw_response.dart';
import 'package:poka_fugou_app/repository/request_interface.dart';

/// カードドローリクエスト
class DrawDeckRequest extends RequestInterface<DrawResponse> {
  final String deckId;
  final int cardCount;
  DrawDeckRequest({required this.deckId, required this.cardCount});

  @override
  String get method => 'GET';
  @override
  String get segment => '$deckId/draw';
  @override
  Map<String, dynamic>? get data => {'count': cardCount};

  @override
  DrawResponse parse(Map<String, dynamic> json) => DrawResponse.fromJson(json);
}
