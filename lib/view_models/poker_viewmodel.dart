import 'package:flutter/material.dart';
import 'package:poka_fugou_app/constants/strings.dart';
import 'package:poka_fugou_app/models/ai/simple_ai.dart';
import 'package:poka_fugou_app/models/hand_evaluator.dart';
import 'package:poka_fugou_app/models/api/playing_card.dart';
import 'package:poka_fugou_app/repository/api_connection.dart';
import 'package:poka_fugou_app/repository/repuest/draw_deck_request.dart';
import 'package:poka_fugou_app/view_models/main_viewmodel.dart';
import 'package:poka_fugou_app/views/view_container/dialog/error_dialog.dart';
import 'package:poka_fugou_app/views/view_container/dialog/progress_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ポーカーViewModel
class PokerViewModel extends ChangeNotifier {
  final MainViewModel mainViewModel;
  PokerViewModel(this.mainViewModel);

  List<PlayingCard> get myCardList => mainViewModel.myCardList;
  List<PlayingCard> get cardList1 => mainViewModel.cardList1;

  /// 選択された(交換する)カードリスト
  List<PlayingCard> selectedMyCards = [];

  /// 相手1の交換カードリスト
  List<PlayingCard> selectedCards1 = [];

  /// 交換したかどうか
  bool isExchanged = false;

  /// 大富豪画面に遷移するかどうか
  bool isGoDaifugoScreen = false;

  /// 相手のハンドを見せるかどうか,勝敗結果ダイアログを表示させるかどうか
  ValueNotifier<bool> isOpenHands = ValueNotifier(false);

  // 結果テキスト
  String resultStr = "";
  String myHandStr = "";
  String playerHandStr = "";

  // Future<void> clearAll() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.clear();
  //   selectedMyCards = [];
  //   selectedCards1 = [];
  //   isExchanged = false;
  //   isOpenHands.value = false;
  //   resultStr = "";
  //   myHandStr = "";
  //   playerHandStr = "";
  //   notifyListeners();
  //   return Future.value();
  // }

  /// 初回カードドロー
  Future<void> firstDrawCard(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final deckId = prefs.getString("deckId");
    ApiConnection api = ApiConnection();

    if (!context.mounted) return;
    final response = await api.startRequest(
      context,
      DrawDeckRequest(deckId: deckId ?? '', cardCount: 5),
    );
    if (response == null) return;
    mainViewModel.updateRemaining(response.remaining);
    if (myCardList.length != 5) {
      mainViewModel.addMyCardList(response.cards);
      if (!context.mounted) return;
      await firstDrawCard(context);
    } else {
      mainViewModel.addCardList1(response.cards);
    }
    notifyListeners();
  }

  /// カード交換ドロー
  Future<void> drawMyCard(BuildContext context, int cardCount) async {
    if (cardCount != 0) {
      final prefs = await SharedPreferences.getInstance();
      final deckId = prefs.getString("deckId");
      ApiConnection api = ApiConnection();

      if (!context.mounted) return;
      final response = await api.startRequest(
        context,
        DrawDeckRequest(deckId: deckId ?? '', cardCount: cardCount),
        isShowProgress: false,
      );
      if (response == null) return;
      mainViewModel.updateRemaining(response.remaining);
      myCardList.addAll(response.cards);
      selectedMyCards.clear();
      notifyListeners();
    }
  }

  /// カード交換ドロー
  Future<void> drawPlayer1Card(BuildContext context, int cardCount) async {
    if (cardCount != 0) {
      final prefs = await SharedPreferences.getInstance();
      final deckId = prefs.getString("deckId");
      ApiConnection api = ApiConnection();

      if (!context.mounted) return;
      final response = await api.startRequest(
        context,
        DrawDeckRequest(deckId: deckId ?? '', cardCount: cardCount),
        isShowProgress: false,
      );
      if (response == null) return;
      mainViewModel.updateRemaining(response.remaining);
      cardList1.addAll(response.cards);
      selectedCards1.clear();
      notifyListeners();
    }
  }

  /// カード交換
  void exchangeCard(BuildContext context) async {
    showProgressDialog(context);
    try {
      myCardList.removeWhere((card) => selectedMyCards.contains(card));
      if (!context.mounted) return;
      await drawMyCard(context, selectedMyCards.length);

      // AIによる不要カード交換
      SimpleAI ai = SimpleAI();
      ai.decideDiscards(cardList1).forEach((index) {
        selectedCards1.add(cardList1[index]);
      });
      cardList1.removeWhere((card) => selectedCards1.contains(card));
      if (!context.mounted) return;
      await drawPlayer1Card(context, selectedCards1.length);

      notifyListeners();
    } catch (e) {
      if (!context.mounted) return;
      showErrorDialog(context, AppStrings.drawError, e.toString());
    } finally {
      if (context.mounted) {
        dismissProgressDialog(context);
      }
      resultHands();
    }
  }

  /// 役判定
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
      final sortedMyCards = PlayingCard.toParsePorkerRank(myCardList);
      mainViewModel.sortedMyCardList(sortedMyCards);
      final sortedCards1 = PlayingCard.toParsePorkerRank(cardList1);
      mainViewModel.sortedCardList1(sortedCards1);
      notifyListeners();
      isOpenHands.value = true;
    });
  }

  void updateViewModel() {
    notifyListeners();
  }
}
