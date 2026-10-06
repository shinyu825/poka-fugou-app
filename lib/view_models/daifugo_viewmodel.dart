import 'package:flutter/material.dart';
import 'package:poka_fugou_app/models/api/playing_card.dart';
import 'package:poka_fugou_app/repository/api_connection.dart';
import 'package:poka_fugou_app/repository/repuest/draw_deck_request.dart';
import 'package:poka_fugou_app/view_models/main_viewmodel.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 大富豪ViewModel
class DaifugoViewModel extends ChangeNotifier {
  final MainViewModel mainViewModel;
  DaifugoViewModel(this.mainViewModel);

  List<PlayingCard> get myCardList => mainViewModel.myCardList;
  List<PlayingCard> get cardList1 => mainViewModel.cardList1;
  int get remaining => mainViewModel.remaining;

  /// 選択された(交換する)カードリスト
  List<PlayingCard> selectedMyCards = [];

  // @override
  // Future<void> clearAll() async {
  //   notifyListeners();
  //   return Future.value();
  // }

  /// 大富豪用ドロー（各7枚になるまで引く）
  Future<void> daifugoDrawCard(BuildContext context) async {
    const handCount = 7;

    if (myCardList.length < handCount) {
      final cards = await _drawCard(context, handCount - myCardList.length);
      if (cards == null) return;
      mainViewModel.addMyCardList(cards);
    }
    if (cardList1.length < handCount) {
      if (!context.mounted) return;
      final cards = await _drawCard(context, handCount - cardList1.length);
      if (cards == null) return;
      mainViewModel.addCardList1(cards);
    }

    final sortedMyHands = PlayingCard.toParseDaifugoRank(myCardList);
    final sortedPlayer1Hands = PlayingCard.toParseDaifugoRank(cardList1);
    mainViewModel.sortedMyCardList(sortedMyHands);
    mainViewModel.sortedCardList1(sortedPlayer1Hands);
    notifyListeners();
  }

  /// 山札からドロー
  Future<List<PlayingCard>?> _drawCard(
    BuildContext context,
    int cardCount,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final deckId = prefs.getString("deckId");
    ApiConnection api = ApiConnection();

    if (!context.mounted) return null;
    final response = await api.startRequest(
      context,
      DrawDeckRequest(deckId: deckId ?? '', cardCount: cardCount),
    );
    if (response == null) return null;
    mainViewModel.updateRemaining(response.remaining);
    return response.cards;
  }
}
