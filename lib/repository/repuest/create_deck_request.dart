import 'package:poka_fugou_app/models/api/create_deck_response.dart';
import 'package:poka_fugou_app/repository/request_interface.dart';

/// 新規デッキ取得リクエスト
class CreateDeckRequest extends RequestInterface<CreateDeckResponse> {
  final int deckCount;
  CreateDeckRequest({required this.deckCount});

  @override
  String get method => 'GET';
  @override
  String get segment => 'new/shuffle';
  @override
  Map<String, dynamic>? get data => {
    'deck_count': deckCount,
    'jokers_enabled': true,
  };

  @override
  CreateDeckResponse parse(Map<String, dynamic> json) =>
      CreateDeckResponse.fromJson(json);
}
