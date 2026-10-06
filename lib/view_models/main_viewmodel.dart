import 'package:flutter/material.dart';
import 'package:poka_fugou_app/models/api/playing_card.dart';
import 'package:poka_fugou_app/repository/api_connection.dart';
import 'package:poka_fugou_app/repository/repuest/create_deck_request.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// メインViewModel
class MainViewModel extends ChangeNotifier {
  /// 自分のカードリスト
  List<PlayingCard> myCardList = [];

  /// 相手1のカードリスト
  List<PlayingCard> cardList1 = [];

  /// ポーカー画面に遷移するかどうか
  bool isGoPokerScreen = false;

  /// 山札の残り枚数
  int remaining = 0;

  // Future<void> clearAll() async {
  //   isGoPokerScreen = false;
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.clear();
  //   notifyListeners();
  //   return Future.value();
  // }

  /// ゲームをリセット
  void resetGame() {
    myCardList = [];
    cardList1 = [];
    isGoPokerScreen = false;
    remaining = 0;
    notifyListeners();
  }

  /// 新規デッキ作成
  Future<void> createDeck(BuildContext context) async {
    if (!context.mounted) return;
    ApiConnection api = ApiConnection();

    final response = await api.startRequest(
      context,
      CreateDeckRequest(deckCount: 1),
    );
    if (response == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("deckId", response.deckId);
    remaining = response.remaining;

    isGoPokerScreen = true;
  }

  /// 山札の残り枚数を更新
  void updateRemaining(int count) {
    remaining = count;
    notifyListeners();
  }

  /// 自分のカードリストに新規追加
  void addMyCardList(List<PlayingCard> list) {
    myCardList.addAll(list);
    notifyListeners();
  }

  /// 自分のカードリストを並び替え
  void sortedMyCardList(List<PlayingCard> list) {
    myCardList = list;
    notifyListeners();
  }

  /// 相手のカードリストに新規追加
  void addCardList1(List<PlayingCard> list) {
    cardList1.addAll(list);
    notifyListeners();
  }

  /// 相手のカードリストを並び替え
  void sortedCardList1(List<PlayingCard> list) {
    cardList1 = list;
    notifyListeners();
  }
}
