import 'package:flutter/material.dart';
import 'package:poka_fugou_app/constants/strings.dart';
import 'package:poka_fugou_app/models/ai/simple_ai.dart';
import 'package:poka_fugou_app/models/hand_evaluator.dart';
import 'package:poka_fugou_app/models/api/playing_card.dart';
import 'package:poka_fugou_app/repository/api_connection.dart';
import 'package:poka_fugou_app/repository/repuest/create_deck_request.dart';
import 'package:poka_fugou_app/repository/repuest/draw_deck_request.dart';
import 'package:poka_fugou_app/views/view_container/dialog/progress_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainViewModel extends ChangeNotifier {
  // 自分のカードリスト
  List<PlayingCard> myCardList = [];
  // 相手1のカードリスト
  List<PlayingCard> cardList1 = [];
  // 選択された(交換する)カードリスト
  List<PlayingCard> selectedMyCards = [];
  // 相手1の交換カードリスト
  List<PlayingCard> selectedCards1 = [];

  // ポーカー画面に遷移するかどうか
  bool isGoPokerScreen = false;
  // 交換したかどうか
  bool isExchanged = false;
  // 相手のハンドを見せるかどうか,勝敗結果ダイアログを表示させるかどうか
  ValueNotifier<bool> isOpenHands = ValueNotifier(false);

  String resultStr = "";
  String myHandStr = "";
  String playerHandStr = "";

  Future<void> clearAll() async {
    myCardList.clear();
    cardList1.clear();
    selectedMyCards.clear();
    selectedCards1.clear();
    isGoPokerScreen = false;
    isExchanged = false;
    isOpenHands.value = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
    return Future.value();
  }

  // 新規デッキ作成
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

    isGoPokerScreen = true;
  }

  // 初回カードドロー
  Future<void> firstDrawCard(BuildContext context) async {
    if (!context.mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final deckId = prefs.getString("deckId");
    ApiConnection api = ApiConnection();

    final response = await api.startRequest(
      context,
      DrawDeckRequest(deckId: deckId ?? '', cardCount: 5),
    );
    if (response == null) return;
    if (myCardList.length != 5) {
      myCardList = response.cards;
      firstDrawCard(context);
    } else {
      cardList1 = response.cards;
    }
    notifyListeners();
  }

  // カード交換ドロー
  Future<void> drawMyCard(BuildContext context, int cardCount) async {
    if (cardCount != 0) {
      if (!context.mounted) return;
      final prefs = await SharedPreferences.getInstance();
      final deckId = prefs.getString("deckId");
      ApiConnection api = ApiConnection();

      final response = await api.startRequest(
        context,
        DrawDeckRequest(deckId: deckId ?? '', cardCount: cardCount),
        isShowProgress: false,
      );
      if (response == null) return;
      myCardList.addAll(response.cards);
      selectedMyCards.clear();
      notifyListeners();
    }
  }

  // カード交換ドロー
  Future<void> drawPlayer1Card(BuildContext context, int cardCount) async {
    if (cardCount != 0) {
      if (!context.mounted) return;
      final prefs = await SharedPreferences.getInstance();
      final deckId = prefs.getString("deckId");
      ApiConnection api = ApiConnection();

      final response = await api.startRequest(
        context,
        DrawDeckRequest(deckId: deckId ?? '', cardCount: cardCount),
        isShowProgress: false,
      );
      if (response == null) return;
      cardList1.addAll(response.cards);
      selectedCards1.clear();
      notifyListeners();
    }
  }

  // カード交換
  void exchangeCard(BuildContext context) async {
    showProgressDialog(context);
    try {
      myCardList.removeWhere((card) => selectedMyCards.contains(card));
      await drawMyCard(context, selectedMyCards.length);

      // AIによる不要カード交換
      SimpleAI ai = SimpleAI();
      ai.decideDiscards(cardList1).forEach((index) {
        selectedCards1.add(cardList1[index]);
      });
      cardList1.removeWhere((card) => selectedCards1.contains(card));
      await drawPlayer1Card(context, selectedCards1.length);

      notifyListeners();
    } catch (e) {
      debugPrint("ドローエラー" + e.toString());
    } finally {
      dismissProgressDialog(context);
      resultHands();
    }
  }

  // 役判定
  void resultHands() {
    final myHandRank = HandEvaluator.evaluate5(myCardList);
    final handRank1 = HandEvaluator.evaluate5(cardList1);

    final result = myHandRank.compareTo(handRank1);
    if (result > 0) {
      resultStr = AppStrings.youWin;
    } else if (result < 0) {
      resultStr = AppStrings.youLose;
    } else {
      resultStr = AppStrings.draw;
    }
    myHandStr = '${myHandRank.rank.jpName}';
    playerHandStr = "${handRank1.rank.jpName}";

    Future.delayed(Duration(seconds: 2), () {
      // 役判定のためにランク順にソート
      final sortedMyCards = PlayingCard.toParseRank(myCardList);
      myCardList = sortedMyCards;
      final sortedCards1 = PlayingCard.toParseRank(cardList1);
      cardList1 = sortedCards1;
      notifyListeners();
      isOpenHands.value = true;
    });
  }

  void updateViewModel() {
    notifyListeners();
  }
}
