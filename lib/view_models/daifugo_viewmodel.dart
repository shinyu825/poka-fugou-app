import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:poka_fugou_app/constants/strings.dart';
import 'package:poka_fugou_app/models/api/playing_card.dart';
import 'package:poka_fugou_app/models/daifugo/daifugo_ai.dart';
import 'package:poka_fugou_app/models/daifugo/daifugo_player.dart';
import 'package:poka_fugou_app/models/daifugo/daifugo_rules.dart';
import 'package:poka_fugou_app/models/daifugo/daifugo_state.dart';
import 'package:poka_fugou_app/models/daifugo/field_play.dart';
import 'package:poka_fugou_app/repository/repuest/draw_deck_request.dart';
import 'package:poka_fugou_app/repository/repuest/return_cards_request.dart';
import 'package:poka_fugou_app/repository/repuest/shuffle_deck_request.dart';
import 'package:poka_fugou_app/view_models/base_viewmodel.dart';
import 'package:poka_fugou_app/view_models/main_viewmodel.dart';

/// 大富豪の進行段階
enum DaifugoPhase {
  /// 配布中（開始前）
  dealing,

  /// 通常の手番
  playing,

  /// 7 で渡すカードを選択中
  selectingGive,

  /// 10 で捨てるカードを選択中
  selectingDiscard,

  /// Q ボンバーの数字を選択中
  selectingBomber,

  /// 決着
  finished,
}

/// 大富豪ViewModel
class DaifugoViewModel extends BaseViewModel {
  final MainViewModel mainViewModel;

  /// CPU が行動するまでの待ち時間（テストでは短くする）
  final Duration cpuDelay;

  /// 決着から結果ダイアログまでの待ち時間
  final Duration resultDelay;

  /// 場が流れるときに、流れる前の場を見せておく時間
  final Duration flowDelay;

  final Random _random;

  DaifugoViewModel(
    this.mainViewModel, {
    super.api,
    this.cpuDelay = const Duration(seconds: 1),
    this.resultDelay = const Duration(seconds: 2),
    this.flowDelay = const Duration(seconds: 2),
    Random? random,
  }) : _random = random ?? Random(),
       pokerMyPoint = mainViewModel.myPoint;

  static const int handCount = 7;
  static const int forbiddenPoint = 10;

  final DaifugoAI _ai = DaifugoAI();

  List<PlayingCard> get myCardList => mainViewModel.myCardList;
  List<PlayingCard> get cardList1 => mainViewModel.cardList1;
  int get remaining => mainViewModel.remaining;
  int get myPoint => mainViewModel.myPoint;
  int get point1 => mainViewModel.point1;
  DaifugoState get state => mainViewModel.daifugo;

  /// 流れる前の場（流れた直後に 2 秒見せる。null なら今の場）
  List<FieldPlay>? _playsBeforeFlow;

  /// 画面に出す場のカード
  List<FieldPlay> get fieldPlays => _playsBeforeFlow ?? state.fieldPlays;

  /// 大富豪開始時点のポイント（最終結果でポーカー分として表示）
  final int pokerMyPoint;

  DaifugoPhase phase = DaifugoPhase.dealing;

  /// 選択中のカード（出す / 渡す / 捨てる）
  List<PlayingCard> selectedMyCards = [];

  /// Q ボンバーで選択中の数字
  List<String> selectedValues = [];

  /// 7 / 10 / Q の効果の枚数
  int pendingCount = 0;

  /// 直前の行動の説明
  String message = '';

  /// CPU の行動や結果表示までの演出待ち（この間は画面操作を受け付けない）
  bool isWaiting = false;

  /// 相手の手札を見せるかどうか（決着後）
  bool isOpenHands = false;

  /// 山札が足りなくなった（ダイアログを出してスタート画面へ）
  bool isDeckExhausted = false;

  /// 結果ダイアログ・最終結果ダイアログの表示回数（増えるたびに表示する）
  ValueNotifier<int> resultCount = ValueNotifier(0);
  ValueNotifier<int> finalResultCount = ValueNotifier(0);

  // 結果
  String resultStr = '';
  List<String> resultDetails = [];
  int pointDelta = 0;

  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    resultCount.dispose();
    finalResultCount.dispose();
    super.dispose();
  }

  /// 自分の手番か（演出待ちの間はボタンを出さない）
  bool get isMyTurn =>
      !isWaiting &&
      phase == DaifugoPhase.playing &&
      state.turn == DaifugoPlayer.me;

  /// 選べるカード（null なら制限なし・タップ不可）
  Set<PlayingCard>? get selectableCards {
    switch (phase) {
      case DaifugoPhase.playing:
        if (!isMyTurn) return null;
        return DaifugoRules.selectableCards(
          myCardList,
          selectedMyCards,
          state,
        );
      case DaifugoPhase.selectingGive:
      case DaifugoPhase.selectingDiscard:
        return selectedMyCards.length >= pendingCount
            ? selectedMyCards.toSet()
            : myCardList.toSet();
      default:
        return null;
    }
  }

  bool get isHandInteractive => selectableCards != null;

  /// 左ボタンの文言（null なら非表示）
  String? get leftButtonLabel {
    switch (phase) {
      case DaifugoPhase.playing:
        if (!isMyTurn) return null;
        if (selectedMyCards.isNotEmpty) return AppStrings.cancel;
        return state.isFieldEmpty ? null : AppStrings.pass;
      case DaifugoPhase.selectingGive:
      case DaifugoPhase.selectingDiscard:
        return selectedMyCards.isEmpty ? AppStrings.pass : AppStrings.cancel;
      case DaifugoPhase.selectingBomber:
        return selectedValues.isEmpty ? null : AppStrings.cancel;
      default:
        return null;
    }
  }

  /// 右ボタンの文言（null なら非表示）
  String? get rightButtonLabel {
    switch (phase) {
      case DaifugoPhase.playing:
        return isMyTurn && selectedMyCards.isNotEmpty ? AppStrings.put : null;
      case DaifugoPhase.selectingGive:
        return selectedMyCards.isEmpty ? null : AppStrings.give;
      case DaifugoPhase.selectingDiscard:
        return selectedMyCards.isEmpty ? null : AppStrings.discard;
      case DaifugoPhase.selectingBomber:
        return selectedValues.isEmpty ? null : AppStrings.decide;
      default:
        return null;
    }
  }

  bool get isRightButtonEnabled {
    switch (phase) {
      case DaifugoPhase.playing:
        return DaifugoRules.canPlay(selectedMyCards, state);
      case DaifugoPhase.selectingBomber:
        return selectedValues.length == pendingCount;
      default:
        return true;
    }
  }

  void onLeftButton() {
    switch (phase) {
      case DaifugoPhase.playing:
        if (selectedMyCards.isNotEmpty) {
          clearSelection();
        } else {
          pass();
        }
      case DaifugoPhase.selectingGive:
      case DaifugoPhase.selectingDiscard:
        if (selectedMyCards.isNotEmpty) {
          clearSelection();
        } else {
          skipEffect();
        }
      case DaifugoPhase.selectingBomber:
        clearSelection();
      default:
        break;
    }
  }

  void onRightButton() {
    switch (phase) {
      case DaifugoPhase.playing:
        playSelected();
      case DaifugoPhase.selectingGive:
        confirmGive();
      case DaifugoPhase.selectingDiscard:
        confirmDiscard();
      case DaifugoPhase.selectingBomber:
        confirmBomber();
      default:
        break;
    }
  }

  /// カードの選択を切り替える（選べないカードは無視）
  void toggleSelectMyCard(PlayingCard card) {
    if (selectedMyCards.contains(card)) {
      selectedMyCards.remove(card);
    } else {
      final selectable = selectableCards;
      if (selectable == null || !selectable.contains(card)) return;
      selectedMyCards.add(card);
    }
    notifyListeners();
  }

  /// Q ボンバーの数字の選択を切り替える（上限に達したら外さないと選べない）
  void toggleSelectValue(String value) {
    if (phase != DaifugoPhase.selectingBomber) return;
    if (selectedValues.contains(value)) {
      selectedValues.remove(value);
    } else if (selectedValues.length < pendingCount) {
      selectedValues.add(value);
    }
    notifyListeners();
  }

  void clearSelection() {
    selectedMyCards.clear();
    selectedValues.clear();
    notifyListeners();
  }

  /// 大富豪用ドロー（各 7 枚になるまで引く）。終わったらゲーム開始
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
    _sortHands();
    if (phase == DaifugoPhase.dealing) _startGame();
    notifyListeners();
  });

  /// 自分の番: 選択中のカードを出す
  Future<void> playSelected() async {
    if (!isMyTurn || !DaifugoRules.canPlay(selectedMyCards, state)) return;
    final cards = [...selectedMyCards];
    selectedMyCards.clear();
    await _play(DaifugoPlayer.me, cards);
  }

  /// 自分の番: パス
  void pass() {
    if (!isMyTurn || state.isFieldEmpty) return;
    _pass(DaifugoPlayer.me);
  }

  /// 7 / 10: 渡さない・捨てない
  void skipEffect() {
    if (phase != DaifugoPhase.selectingGive &&
        phase != DaifugoPhase.selectingDiscard) {
      return;
    }
    message = AppStrings.noEffect(AppStrings.you);
    _afterEffect();
  }

  /// 7: 選んだカードを相手に渡す
  void confirmGive() {
    if (phase != DaifugoPhase.selectingGive || selectedMyCards.isEmpty) return;
    final cards = [...selectedMyCards];
    selectedMyCards.clear();
    _giveCards(DaifugoPlayer.me, cards);
    message = AppStrings.gaveCards(AppStrings.you, cards.length);
    if (myCardList.isEmpty) {
      _finish(winner: DaifugoPlayer.me, forbidden: false);
      return;
    }
    _afterEffect();
  }

  /// 10: 選んだカードを捨てる
  void confirmDiscard() {
    if (phase != DaifugoPhase.selectingDiscard || selectedMyCards.isEmpty) {
      return;
    }
    final cards = [...selectedMyCards];
    selectedMyCards.clear();
    mainViewModel.removeMyCards(cards);
    message = AppStrings.discardedCards(AppStrings.you, cards.length);
    if (myCardList.isEmpty) {
      _finish(winner: DaifugoPlayer.me, forbidden: false);
      return;
    }
    _afterEffect();
  }

  /// Q: 選んだ数字でボンバー
  void confirmBomber() {
    if (phase != DaifugoPhase.selectingBomber ||
        selectedValues.length != pendingCount) {
      return;
    }
    final values = [...selectedValues];
    selectedValues.clear();
    if (_applyBomber(DaifugoPlayer.me, values)) return;
    _afterEffect();
  }

  /// 結果ダイアログを閉じた後の処理（ポイント反映 → 最終結果へ）
  void onResultDialogClosed() {
    mainViewModel.addPoints(my: pointDelta, player1: -pointDelta);
    notifyListeners();
    finalResultCount.value++;
  }

  // ---- ゲーム進行 ----

  void _startGame() {
    final DaifugoPlayer starter;
    if (myCardList.any(_isDiamondThree)) {
      starter = DaifugoPlayer.me;
      message = AppStrings.startByDiamondThree(AppStrings.you);
    } else if (cardList1.any(_isDiamondThree)) {
      starter = DaifugoPlayer.opponent;
      message = AppStrings.startByDiamondThree(AppStrings.opponent);
    } else {
      starter = _random.nextBool() ? DaifugoPlayer.me : DaifugoPlayer.opponent;
      message = AppStrings.startByRandom(_nameOf(starter));
    }
    mainViewModel.updateDaifugo(DaifugoState(turn: starter));
    phase = DaifugoPhase.playing;
    _beginTurn();
  }

  /// 手番の開始（禁止あがりのカードだけなら強制的に負け。CPU なら待ってから行動）
  void _beginTurn() {
    final player = state.turn;
    if (player == null || phase == DaifugoPhase.finished) return;
    final hand = _handOf(player);
    if (DaifugoRules.isAllForbidden(hand, isRevolution: state.isRevolution)) {
      message = AppStrings.forbiddenOnly(_nameOf(player));
      _finish(winner: player.next, forbidden: true);
      return;
    }
    phase = DaifugoPhase.playing;
    if (player == DaifugoPlayer.opponent) {
      _startWaiting(_cpuTurn);
    } else {
      notifyListeners();
    }
  }

  Future<void> _cpuTurn() async {
    final play = _ai.choosePlay(cardList1, state);
    if (play == null) {
      _pass(DaifugoPlayer.opponent);
      return;
    }
    await _play(DaifugoPlayer.opponent, play);
  }

  void _pass(DaifugoPlayer player) {
    final before = state.fieldPlays;
    mainViewModel.updateDaifugo(DaifugoRules.pass(state, player));
    message = AppStrings.passed(_nameOf(player));
    _waitFlow(before);
  }

  /// 流れる前の場を [flowDelay] の間見せてから次の手番へ
  void _waitFlow(List<FieldPlay> before) {
    _playsBeforeFlow = before;
    _startWaiting(() async {
      _playsBeforeFlow = null;
      _beginTurn();
    }, delay: flowDelay);
  }

  /// カードを出して効果を処理する
  Future<void> _play(DaifugoPlayer player, List<PlayingCard> cards) async {
    final forbidden = DaifugoRules.isForbiddenFinish(
      cards,
      isRevolution: state.isRevolution,
    );
    _removeCards(player, cards);
    final outcome = DaifugoRules.play(state, player, cards);
    mainViewModel.updateDaifugo(outcome.state);
    message = _playMessage(player, cards, outcome);
    // 流れても出したカードは見せたままにする（決着ならそのまま、続くなら 2 秒後に片付ける）
    if (outcome.flowed) _playsBeforeFlow = outcome.playsBeforeFlow;

    final hand = _handOf(player);
    if (hand.isEmpty && outcome.effect != CardEffect.draw) {
      // 禁止あがりなら出した側の負け
      _finish(winner: forbidden ? player.next : player, forbidden: forbidden);
      return;
    }

    final base = message;
    switch (outcome.effect) {
      case CardEffect.draw:
        final ok = await _drawFor(player, outcome.count);
        message = '$base / $message';
        if (!ok) return;
      case CardEffect.pass:
        if (player == DaifugoPlayer.me) {
          _startSelecting(DaifugoPhase.selectingGive, outcome.count);
          return;
        }
        final give = _ai.chooseGive(cardList1, outcome.count);
        _giveCards(player, give);
        message = '$base / ${AppStrings.receivedCards(give.length)}';
        if (cardList1.isEmpty) {
          _finish(winner: player, forbidden: false);
          return;
        }
      case CardEffect.discard:
        if (player == DaifugoPlayer.me) {
          _startSelecting(DaifugoPhase.selectingDiscard, outcome.count);
          return;
        }
        final discard = _ai.chooseDiscard(cardList1, outcome.count);
        mainViewModel.removeCards1(discard);
        message =
            '$base / ${AppStrings.discardedCards(AppStrings.opponent, discard.length)}';
        if (cardList1.isEmpty) {
          _finish(winner: player, forbidden: false);
          return;
        }
      case CardEffect.bomber:
        if (player == DaifugoPlayer.me) {
          _startSelecting(DaifugoPhase.selectingBomber, outcome.count);
          return;
        }
        final values = _ai.chooseBomberValues(
          cardList1,
          outcome.count,
          isRevolution: state.isRevolution,
        );
        final ended = _applyBomber(player, values);
        message = '$base / $message';
        if (ended) return;
      default:
        break;
    }
    if (outcome.flowed) {
      _waitFlow(outcome.playsBeforeFlow);
      return;
    }
    _beginTurn();
  }

  String _playMessage(
    DaifugoPlayer player,
    List<PlayingCard> cards,
    PlayOutcome outcome,
  ) {
    final names = cards.map((c) => c.shortName).join(' ');
    final notes = <String>[
      if (outcome.revolution) AppStrings.revolution,
      if (outcome.spadeThree) AppStrings.spadeThreeReturn,
      if (outcome.effect == CardEffect.cut) AppStrings.cutEffect,
      if (outcome.effect == CardEffect.skip) AppStrings.skipEffect,
      if (outcome.effect == CardEffect.back) AppStrings.backEffect,
    ];
    final base = AppStrings.played(_nameOf(player), names);
    return notes.isEmpty ? base : '$base（${notes.join('・')}）';
  }

  void _startSelecting(DaifugoPhase next, int count) {
    phase = next;
    pendingCount = count;
    switch (next) {
      case DaifugoPhase.selectingGive:
        message = AppStrings.selectGive(count);
      case DaifugoPhase.selectingDiscard:
        message = AppStrings.selectDiscard(count);
      case DaifugoPhase.selectingBomber:
        message = AppStrings.selectBomber(count);
      default:
        break;
    }
    notifyListeners();
  }

  /// 効果の処理が終わったら次の手番へ（手番は play の結果で決まっている）
  void _afterEffect() {
    phase = DaifugoPhase.playing;
    _beginTurn();
  }

  /// ボンバーを適用し、誰かが上がったら true
  bool _applyBomber(DaifugoPlayer player, List<String> values) {
    final mine = myCardList.where((c) => values.contains(c.value)).toList();
    final theirs = cardList1.where((c) => values.contains(c.value)).toList();
    mainViewModel.removeMyCards(mine);
    mainViewModel.removeCards1(theirs);
    message = AppStrings.bombed(
      _nameOf(player),
      values.map(PlayingCard.displayOf).join('・'),
    );
    // 複数人が同時に 0 枚になったら、出した本人から手番順に上位（人数追加時もこの順）
    if (_handOf(player).isEmpty) {
      _finish(winner: player, forbidden: false);
      return true;
    }
    if (_handOf(player.next).isEmpty) {
      _finish(winner: player.next, forbidden: false);
      return true;
    }
    return false;
  }

  void _giveCards(DaifugoPlayer from, List<PlayingCard> cards) {
    _removeCards(from, cards);
    if (from == DaifugoPlayer.me) {
      mainViewModel.addCards1(cards);
    } else {
      mainViewModel.addMyCards(cards);
    }
    _sortHands();
  }

  /// 決着（勝者の残り枚数は 0。敗者の残り枚数分、革命の倍率をかける）
  void _finish({required DaifugoPlayer winner, required bool forbidden}) {
    phase = DaifugoPhase.finished;
    final loser = winner.next;
    final loserRemaining = _handOf(loser).length;
    final multiplier = state.revolutionCount + 1;
    final points = forbidden ? forbiddenPoint : loserRemaining * multiplier;
    pointDelta = winner == DaifugoPlayer.me ? points : -points;
    resultStr = winner == DaifugoPlayer.me
        ? AppStrings.youWin
        : AppStrings.youLose;
    resultDetails = [
      if (forbidden)
        AppStrings.forbiddenFinish
      else ...[
        AppStrings.remainingCards(_nameOf(loser), loserRemaining),
        if (state.revolutionCount > 0)
          AppStrings.revolutionBonus(state.revolutionCount, multiplier),
      ],
    ];
    isOpenHands = true;
    _startWaiting(() async => resultCount.value++, delay: resultDelay);
  }

  /// 演出の待ち時間を置いてから [action] を実行する
  void _startWaiting(Future<void> Function() action, {Duration? delay}) {
    isWaiting = true;
    notifyListeners();
    _timer?.cancel();
    _timer = Timer(delay ?? cpuDelay, () async {
      isWaiting = false;
      await action();
      notifyListeners();
    });
  }

  // ---- 山札 ----

  /// 6 の効果で引く（山札が尽きたら捨て札を戻す。それでも足りなければ終了）
  Future<bool> _drawFor(DaifugoPlayer player, int count) async {
    return withLoading(() async {
      if (remaining < count && !await _refillDeck()) return false;
      if (remaining < count) {
        isDeckExhausted = true;
        notifyListeners();
        return false;
      }
      final cards = await _drawCards(count);
      if (cards == null) return false;
      if (player == DaifugoPlayer.me) {
        mainViewModel.addMyCards(cards);
      } else {
        mainViewModel.addCards1(cards);
      }
      _sortHands();
      message = AppStrings.drawEffect(_nameOf(player), cards.length);
      return true;
    });
  }

  /// ポーカーで手放したカードを山札に戻してシャッフル（成功したら true）
  Future<bool> _refillDeck() async {
    final discards = mainViewModel.discardedCards;
    if (discards.isEmpty) return true;
    final returned = await runApi(
      ReturnCardsRequest(
        deckId: mainViewModel.deckId,
        codes: discards.map((c) => c.code).toList(),
      ),
    );
    if (returned == null) return false;
    final shuffled = await runApi(
      ShuffleDeckRequest(deckId: mainViewModel.deckId),
    );
    if (shuffled == null) return false;
    mainViewModel.clearDiscardedCards();
    mainViewModel.updateRemaining(shuffled.remaining);
    return true;
  }

  /// 山札からドロー（失敗時は null）
  Future<List<PlayingCard>?> _drawCards(int cardCount) async {
    final response = await runApi(
      DrawDeckRequest(deckId: mainViewModel.deckId, cardCount: cardCount),
    );
    if (response == null) return null;
    mainViewModel.updateRemaining(response.remaining);
    return response.cards;
  }

  // ---- 補助 ----

  List<PlayingCard> _handOf(DaifugoPlayer player) =>
      player == DaifugoPlayer.me ? myCardList : cardList1;

  void _removeCards(DaifugoPlayer player, List<PlayingCard> cards) {
    if (player == DaifugoPlayer.me) {
      mainViewModel.removeMyCards(cards);
    } else {
      mainViewModel.removeCards1(cards);
    }
  }

  void _sortHands() {
    mainViewModel.setMyCards(PlayingCard.toParseDaifugoRank(myCardList));
    mainViewModel.setCards1(PlayingCard.toParseDaifugoRank(cardList1));
  }

  String _nameOf(DaifugoPlayer player) =>
      player == DaifugoPlayer.me ? AppStrings.you : AppStrings.opponent;

  static bool _isDiamondThree(PlayingCard c) =>
      c.value == '3' && c.suit == 'DIAMONDS';
}
