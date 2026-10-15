import 'package:poka_fugou_app/models/api/create_deck_response.dart';
import 'package:poka_fugou_app/repository/request_interface.dart';

/// 山札の残りをシャッフルするリクエスト
class ShuffleDeckRequest extends RequestInterface<CreateDeckResponse> {
  final String deckId;
  ShuffleDeckRequest({required this.deckId});

  @override
  String get method => 'GET';
  @override
  String get segment => '$deckId/shuffle';
  @override
  Map<String, dynamic>? get data => {'remaining': true};

  @override
  CreateDeckResponse parse(Map<String, dynamic> json) =>
      CreateDeckResponse.fromJson(json);
}
