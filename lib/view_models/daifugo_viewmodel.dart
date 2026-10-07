import 'package:poka_fugou_app/models/api/playing_card.dart';
import 'package:poka_fugou_app/repository/repuest/draw_deck_request.dart';
import 'package:poka_fugou_app/view_models/base_viewmodel.dart';
import 'package:poka_fugou_app/view_models/main_viewmodel.dart';

/// 大富豪ViewModel
class DaifugoViewModel extends BaseViewModel {
  final MainViewModel mainViewModel;
  DaifugoViewModel(this.mainViewModel, {super.api});

  static const int handCount = 7;

  List<PlayingCard> get myCardList => mainViewModel.myCardList;
  List<PlayingCard> get cardList1 => mainViewModel.cardList1;
  int get remaining => mainViewModel.remaining;
  int get myPoint => mainViewModel.myPoint;
  int get point1 => mainViewModel.point1;

  /// 選択された(出す)カードリスト
  List<PlayingCard> selectedMyCards = [];

  /// 出すカードの選択を切り替える
  void toggleSelectMyCard(PlayingCard card) {
    if (selectedMyCards.contains(card)) {
      selectedMyCards.remove(card);
    } else {
      selectedMyCards.add(card);
    }
    notifyListeners();
  }

  /// 大富豪用ドロー（各7枚になるまで引く）
  Future<void> daifugoDrawCard() => withLoading(() async {
    if (myCardList.length < handCount) {
      final cards = await _drawCards(handCount - myCardList.length);
      if (cards == null) return;
      mainViewModel.addMyCards(cards);
    }
    if (cardList1.length < handCount) {
      final cards = await _drawCards(handCount - cardList1.length);
      if (cards == null) return;
      mainViewModel.addCards1(cards);
    }

    mainViewModel.setMyCards(PlayingCard.toParseDaifugoRank(myCardList));
    mainViewModel.setCards1(PlayingCard.toParseDaifugoRank(cardList1));
    notifyListeners();
  });

  /// 山札からドロー（失敗時はnull）
  Future<List<PlayingCard>?> _drawCards(int cardCount) async {
    final response = await runApi(
      DrawDeckRequest(deckId: mainViewModel.deckId, cardCount: cardCount),
    );
    if (response == null) return null;
    mainViewModel.updateRemaining(response.remaining);
    return response.cards;
  }
}
