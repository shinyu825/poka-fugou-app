import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:poka_fugou_app/constants/difficulty.dart';
import 'package:poka_fugou_app/constants/strings.dart';
import 'package:poka_fugou_app/models/ai/advanced_ai.dart';
import 'package:poka_fugou_app/models/ai/simple_ai.dart';
import 'package:poka_fugou_app/models/api/playing_card.dart';
import 'package:poka_fugou_app/models/hand_evaluator.dart';
import 'package:poka_fugou_app/repository/repuest/draw_deck_request.dart';
import 'package:poka_fugou_app/view_models/base_viewmodel.dart';
import 'package:poka_fugou_app/view_models/main_viewmodel.dart';

/// ポーカーViewModel
class PokerViewModel extends BaseViewModel {
  final MainViewModel mainViewModel;

  /// 結果ダイアログを出すまでの演出の待ち時間（テストでは短くする）
  final Duration resultDelay;

  PokerViewModel(
    this.mainViewModel, {
    super.api,
    this.resultDelay = const Duration(seconds: 2),
  });

  static const int handCount = 5;

  List<PlayingCard> get myCardList => mainViewModel.myCardList;
  List<PlayingCard> get cardList1 => mainViewModel.cardList1;
  int get myPoint => mainViewModel.myPoint;
  int get point1 => mainViewModel.point1;

  /// 選択された(交換する)カードリスト
  List<PlayingCard> selectedMyCards = [];

  /// 交換したかどうか（結果ダイアログを閉じた後にtrue）
  bool isExchanged = false;

  /// 交換ボタンを押してから結果が出るまでの判定中かどうか
  bool isJudging = false;

  /// 結果表示までの演出待ち（この間は画面操作を受け付けない）
  bool isWaiting = false;

  /// 今回のポーカーで増減するポイント（ダイアログ表示用。閉じたときに反映）
  int pointDelta = 0;
  bool _isPointPending = false;

  /// 相手のハンドを見せるかどうか
  bool isOpenHands = false;

  /// 勝敗結果ダイアログの表示回数（増えるたびに表示する）
  ValueNotifier<int> resultCount = ValueNotifier(0);

  /// 引き分けでサドンデス中かどうか
  bool isTieBreak = false;

  /// サドンデスで引いたカード
  PlayingCard? myTieCard;
  PlayingCard? tieCard1;

  /// サドンデスのカードを表にしたかどうか
  bool isTieCardsOpen = false;

  // 結果テキスト
  String resultStr = '';
  String myHandStr = '';
  String playerHandStr = '';

  /// 演出待ちのタイマー（画面を閉じたら止める）
  Timer? _resultTimer;

  @override
  void dispose() {
    _resultTimer?.cancel();
    resultCount.dispose();
    super.dispose();
  }

  /// 初回カードドロー（自分 → 相手の順に5枚ずつ）
  Future<void> firstDrawCard() => withLoading(() async {
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
    notifyListeners();
  });

  /// 交換するカードの選択を切り替える
  void toggleSelectMyCard(PlayingCard card) {
    if (isJudging) return;
    if (selectedMyCards.contains(card)) {
      selectedMyCards.remove(card);
    } else {
      selectedMyCards.add(card);
    }
    notifyListeners();
  }

  /// カード交換（自分 → 相手の順。途中で失敗したら判定せず交換前に戻す）
  Future<void> exchangeCard() async {
    if (isJudging) return;
    isJudging = true;
    notifyListeners();
    final isSuccess = await withLoading(_exchangeCard);
    if (isSuccess) {
      resultHands();
    } else {
      isJudging = false;
    }
    notifyListeners();
  }

  /// 交換の本体（成功したらtrue）
  Future<bool> _exchangeCard() async {
    // 自分の交換
    final myDrawn = await _drawCards(selectedMyCards.length);
    if (myDrawn == null) return false;
    mainViewModel.addDiscardedCards(selectedMyCards);
    mainViewModel.setMyCards([
      ...myCardList.where((card) => !selectedMyCards.contains(card)),
      ...myDrawn,
    ]);
    selectedMyCards.clear();

    // AIによる交換
    if (mainViewModel.difficulty == Difficulty.hard) {
      // 強化版: 4枚引いて9枚から最強の5枚を選ぶ
      final drawn = await _drawCards(AdvancedAI.drawCount);
      if (drawn == null) return false;
      final candidates = [...cardList1, ...drawn];
      final best = AdvancedAI().selectBestHand(candidates);
      mainViewModel.addDiscardedCards(
        candidates.where((card) => !best.contains(card)).toList(),
      );
      mainViewModel.setCards1(best);
    } else {
      // シンプル版: 役に応じた定石で交換
      final discards = SimpleAI()
          .decideDiscards(cardList1)
          .map((index) => cardList1[index])
          .toList();
      final drawn = await _drawCards(discards.length);
      if (drawn == null) return false;
      mainViewModel.addDiscardedCards(discards);
      mainViewModel.setCards1([
        ...cardList1.where((card) => !discards.contains(card)),
        ...drawn,
      ]);
    }
    return true;
  }

  /// 役判定（待ち時間の後に結果ダイアログを表示）
  void resultHands() {
    final myHandRank = HandEvaluator.evaluate5(myCardList);
    final handRank1 = HandEvaluator.evaluate5(cardList1);

    final result = myHandRank.compareTo(handRank1);
    if (result > 0) {
      resultStr = AppStrings.youWin;
      _setPendingPoints(myHandRank.rank.point);
    } else if (result < 0) {
      resultStr = AppStrings.youLose;
      _setPendingPoints(-handRank1.rank.point);
    } else {
      resultStr = AppStrings.draw;
      _setPendingPoints(0);
      isTieBreak = true;
    }
    myHandStr = myHandRank.jpNameWithDetail;
    playerHandStr = handRank1.jpNameWithDetail;

    _startWaiting(() {
      // 役が分かりやすいようにランク順にソート
      mainViewModel.setMyCards(PlayingCard.toParsePorkerRank(myCardList));
      mainViewModel.setCards1(PlayingCard.toParsePorkerRank(cardList1));
      isOpenHands = true;
    });
  }

  /// サドンデスのドロー（自分 → 相手の順に1枚ずつ引き、裏向きで持つ）
  Future<void> drawTieBreakCards() => withLoading(() async {
    final myCard = await _drawOneCard();
    if (myCard == null) return;
    final card1 = await _drawOneCard();
    if (card1 == null) return;
    myTieCard = myCard;
    tieCard1 = card1;
    isTieCardsOpen = false;
    mainViewModel.addDiscardedCards([myCard, card1]);
    notifyListeners();
  });

  /// サドンデスのカードを表にして、待ち時間の後に判定結果を表示
  void openTieBreakCards() {
    final myCard = myTieCard;
    final card1 = tieCard1;
    if (myCard == null || card1 == null) return;
    isTieCardsOpen = true;

    _startWaiting(() {
      final myScore = HandEvaluator.evaluate5(myCardList);
      final score1 = HandEvaluator.evaluate5(cardList1);
      final rank = myScore.rank;
      final result = _tieBreakRank(myCard).compareTo(_tieBreakRank(card1));
      if (result > 0) {
        resultStr = AppStrings.youWin;
        _setPendingPoints(rank.point);
        isTieBreak = false;
      } else if (result < 0) {
        resultStr = AppStrings.youLose;
        _setPendingPoints(-rank.point);
        isTieBreak = false;
      } else {
        resultStr = AppStrings.draw;
        _setPendingPoints(0);
      }
      myHandStr = AppStrings.tieBreakHand(
        myScore.jpNameWithDetail,
        myCard.displayValue,
      );
      playerHandStr = AppStrings.tieBreakHand(
        score1.jpNameWithDetail,
        card1.displayValue,
      );
    });
  }

  /// 結果ダイアログを閉じた後の処理（ポイント反映。再び引き分けなら引き直し）
  void onResultDialogClosed() {
    isExchanged = true;
    if (_isPointPending) {
      mainViewModel.addPoints(my: pointDelta, player1: -pointDelta);
      _isPointPending = false;
    }
    if (isTieBreak) {
      myTieCard = null;
      tieCard1 = null;
      isTieCardsOpen = false;
    }
    notifyListeners();
  }

  /// 大富豪へ進む前の後始末（戻ってきたときに相手の手札を裏に戻す）
  void onGoDaifugo() {
    isOpenHands = false;
    notifyListeners();
  }

  /// 演出の待ち時間を置いてから[onDone]を実行し、結果ダイアログを出す
  void _startWaiting(void Function() onDone) {
    isWaiting = true;
    notifyListeners();
    _resultTimer?.cancel();
    _resultTimer = Timer(resultDelay, () {
      onDone();
      isWaiting = false;
      notifyListeners();
      resultCount.value++;
    });
  }

  /// 増減ポイントを保持（ダイアログを閉じたときに反映する）
  void _setPendingPoints(int myDelta) {
    pointDelta = myDelta;
    _isPointPending = myDelta != 0;
  }

  /// サドンデスのカードの強さ（A > K > ... > 2、ジョーカーは最強）
  int _tieBreakRank(PlayingCard card) {
    return card.isJoker ? 15 : parsePorkerRank(card.value);
  }

  /// 山札から1枚引く
  Future<PlayingCard?> _drawOneCard() async {
    final cards = await _drawCards(1);
    return cards?.first;
  }

  /// 山札からドロー（失敗時はnull）
  Future<List<PlayingCard>?> _drawCards(int cardCount) async {
    if (cardCount == 0) return [];
    final response = await runApi(
      DrawDeckRequest(deckId: mainViewModel.deckId, cardCount: cardCount),
    );
    if (response == null) return null;
    mainViewModel.updateRemaining(response.remaining);
    return response.cards;
  }
}
