import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:poka_fugou_app/constants/strings.dart';
import 'package:poka_fugou_app/models/api/playing_card.dart';
import 'package:poka_fugou_app/models/daifugo/daifugo_player.dart';
import 'package:poka_fugou_app/view_models/daifugo_viewmodel.dart';
import 'package:poka_fugou_app/view_models/main_viewmodel.dart';

import 'helpers/fake_api_client.dart';
import 'helpers/test_cards.dart';

void main() {
  /// ポーカー後の手札 5 枚ずつと山札で大富豪を始める
  Future<DaifugoViewModel> setup(
    List<String> mine,
    List<String> opponent, {
    List<String> deck = const ['4/C', '4/D', '5/C', '5/D'],
    FakeApiClient? api,
    int myPoint = 0,
  }) async {
    final fake = api ?? FakeApiClient(deck: hand(deck));
    final main = MainViewModel(api: fake)
      ..setMyCards(hand(mine))
      ..setCards1(hand(opponent))
      ..updateRemaining(fake.deck.length);
    if (myPoint != 0) main.addPoints(my: myPoint, player1: -myPoint);
    final vm = DaifugoViewModel(
      main,
      api: fake,
      cpuDelay: Duration.zero,
      resultDelay: Duration.zero,
      flowDelay: Duration.zero,
      random: Random(1),
    );
    await vm.daifugoDrawCard();
    return vm;
  }

  /// 演出待ち（Duration.zero のタイマー）を進める
  Future<void> tick() => Future.delayed(Duration.zero);

  PlayingCard find(DaifugoViewModel vm, String value, [String? suit]) =>
      vm.myCardList.firstWhere(
        (c) => c.value == value && (suit == null || c.suit == suit),
      );

  test('各 7 枚になるまで引いて、♦3 を持っている人から始まる', () async {
    final vm = await setup(
      ['3/D', '9/S', '9/H', 'K/C', '2/S'],
      ['7/D', '7/C', '8/S', 'J/C', 'A/H'],
    );
    expect(vm.myCardList.length, 7);
    expect(vm.cardList1.length, 7);
    expect(vm.isMyTurn, isTrue);
    expect(vm.message, AppStrings.startByDiamondThree(AppStrings.you));
    // 最初に出す番で未選択ならボタンは両方非表示
    expect(vm.leftButtonLabel, isNull);
    expect(vm.rightButtonLabel, isNull);
  });

  test('相手が ♦3 を持っていれば相手から。待ち時間の後に相手が出す', () async {
    final vm = await setup(
      ['9/S', '9/H', 'K/C', '2/S', 'A/D'],
      ['3/D', '7/C', '8/S', 'J/C', 'A/H'],
    );
    expect(vm.isMyTurn, isFalse);
    expect(vm.isWaiting, isTrue);
    await tick();
    expect(vm.isWaiting, isFalse);
    expect(vm.state.fieldPlays.length, 1);
    expect(vm.cardList1.length, 6);
    expect(vm.isMyTurn, isTrue);
    // 相手が出していて未選択なら左にパスだけ
    expect(vm.leftButtonLabel, AppStrings.pass);
    expect(vm.rightButtonLabel, isNull);
  });

  test('選択すると左キャンセル・右出す。出せない組み合わせなら出すは無効', () async {
    final vm = await setup(
      ['3/D', '9/S', '9/H', 'K/C', '2/S'],
      ['7/D', '7/C', '8/S', 'J/C', 'A/H'],
    );
    vm.toggleSelectMyCard(find(vm, '9', 'SPADES'));
    expect(vm.leftButtonLabel, AppStrings.cancel);
    expect(vm.rightButtonLabel, AppStrings.put);
    expect(vm.isRightButtonEnabled, isTrue);
    // 9 を選んでいるので K は選べない
    vm.toggleSelectMyCard(find(vm, 'KING'));
    expect(vm.selectedMyCards.length, 1);
    vm.onLeftButton();
    expect(vm.selectedMyCards, isEmpty);
  });

  test('出すと相手の番になり、相手が出せなければパスして自分から', () async {
    final vm = await setup(
      ['3/D', '9/S', '9/H', 'K/C', '2/S'],
      ['7/D', '7/C', '8/S', 'J/C', 'A/H'],
    );
    vm.toggleSelectMyCard(find(vm, '2'));
    await vm.playSelected();
    expect(vm.myCardList.length, 6);
    expect(vm.state.turn, DaifugoPlayer.opponent);
    await tick();
    // 相手はジョーカーを持っていないのでパス → 流れる前の場を見せてから自分の番
    expect(vm.message, AppStrings.passed(AppStrings.opponent));
    expect(vm.state.isFieldEmpty, isTrue);
    expect(vm.fieldPlays.length, 1);
    expect(vm.isWaiting, isTrue);
    await tick();
    expect(vm.fieldPlays, isEmpty);
    expect(vm.isMyTurn, isTrue);
  });

  test('8 切りで流れるときは、出したカードを見せてから自分の番', () async {
    final vm = await setup(
      ['3/D', '8/S', '9/H', 'K/C', '2/S'],
      ['7/D', '7/C', '9/S', 'J/C', 'A/H'],
    );
    vm.toggleSelectMyCard(find(vm, '8'));
    await vm.playSelected();
    expect(vm.state.isFieldEmpty, isTrue);
    expect(vm.fieldPlays.map((p) => p.cards.first.value), ['8']);
    expect(vm.isWaiting, isTrue);
    expect(vm.isMyTurn, isFalse);
    await tick();
    expect(vm.fieldPlays, isEmpty);
    expect(vm.isMyTurn, isTrue);
  });

  test('7 を出すと渡すカードを選び、渡すと相手の手札に入る', () async {
    final vm = await setup(
      ['3/D', '7/S', '7/H', 'K/C', '2/S'],
      ['9/D', '9/C', '8/S', 'J/C', 'A/H'],
    );
    vm.toggleSelectMyCard(find(vm, '7', 'SPADES'));
    vm.toggleSelectMyCard(find(vm, '7', 'HEARTS'));
    await vm.playSelected();
    expect(vm.phase, DaifugoPhase.selectingGive);
    expect(vm.pendingCount, 2);
    expect(vm.leftButtonLabel, AppStrings.pass);
    vm.toggleSelectMyCard(find(vm, '3'));
    vm.toggleSelectMyCard(find(vm, 'KING'));
    // 上限なので 3 枚目は選べない
    vm.toggleSelectMyCard(find(vm, '2'));
    expect(vm.selectedMyCards.length, 2);
    expect(vm.rightButtonLabel, AppStrings.give);
    vm.onRightButton();
    expect(vm.myCardList.length, 3);
    expect(vm.cardList1.length, 9);
    expect(vm.phase, DaifugoPhase.playing);
  });

  test('10 で捨てるカードは山札にも相手にも行かない', () async {
    final vm = await setup(
      ['3/D', '10/S', 'K/C', '2/S', 'A/D'],
      ['9/D', '9/C', '8/S', 'J/C', 'A/H'],
    );
    vm.toggleSelectMyCard(find(vm, '10'));
    await vm.playSelected();
    expect(vm.phase, DaifugoPhase.selectingDiscard);
    vm.toggleSelectMyCard(find(vm, '3'));
    vm.confirmDiscard();
    expect(vm.myCardList.length, 5);
    expect(vm.cardList1.length, 7);
    expect(vm.mainViewModel.discardedCards, isEmpty);
  });

  test('Q ボンバーは出した枚数分の数字を必ず選ぶ。両者のその数字を捨てる', () async {
    final vm = await setup(
      ['3/D', 'Q/S', 'K/C', '2/S', 'A/D'],
      ['9/D', '9/C', '8/S', 'J/C', 'A/H'],
    );
    vm.toggleSelectMyCard(find(vm, 'QUEEN'));
    await vm.playSelected();
    expect(vm.phase, DaifugoPhase.selectingBomber);
    expect(vm.leftButtonLabel, isNull);
    vm.toggleSelectValue('9');
    expect(vm.rightButtonLabel, AppStrings.decide);
    expect(vm.isRightButtonEnabled, isTrue);
    vm.toggleSelectValue('ACE');
    expect(vm.selectedValues, ['9']);
    vm.confirmBomber();
    expect(vm.cardList1.where((c) => c.value == '9'), isEmpty);
    expect(vm.cardList1.length, 5);
  });

  test('6 を出すと本人が引く。最後の 1 枚が 6 でも上がりにならない', () async {
    final vm = await setup(
      ['6/D', '3/S', 'K/C', '2/S', 'A/D'],
      ['9/D', '9/C', '8/S', 'J/C', 'A/H'],
      deck: ['4/C', '4/D', '5/C', '5/D', '10/H'],
    );
    vm.mainViewModel.setMyCards(hand(['6/D']));
    vm.toggleSelectMyCard(find(vm, '6'));
    await vm.playSelected();
    expect(vm.phase, DaifugoPhase.playing);
    expect(vm.myCardList.length, 1);
    expect(vm.myCardList.first.value, '10');
  });

  test('上がると残り枚数分のポイント。ダイアログを閉じると反映して最終結果へ', () async {
    final vm = await setup(
      ['3/D', '9/S', '9/H', 'K/C', '2/S'],
      ['7/D', '7/C', '8/S', 'J/C', 'A/H'],
      myPoint: 3,
    );
    vm.mainViewModel.setMyCards(hand(['K/C']));
    vm.toggleSelectMyCard(find(vm, 'KING'));
    await vm.playSelected();
    expect(vm.phase, DaifugoPhase.finished);
    expect(vm.isWaiting, isTrue);
    await tick();
    expect(vm.resultStr, AppStrings.youWin);
    expect(vm.pointDelta, 7);
    expect(vm.resultCount.value, 1);
    expect(vm.mainViewModel.myPoint, 3);
    vm.onResultDialogClosed();
    expect(vm.mainViewModel.myPoint, 10);
    expect(vm.mainViewModel.point1, -10);
    expect(vm.pokerMyPoint, 3);
    expect(vm.finalResultCount.value, 1);
  });

  test('禁止あがりで上がると ±10 固定で負け', () async {
    final vm = await setup(
      ['3/D', '9/S', '9/H', 'K/C', '2/S'],
      ['7/D', '7/C', '8/S', 'J/C', 'A/H'],
    );
    vm.mainViewModel.setMyCards(hand(['2/C']));
    vm.toggleSelectMyCard(find(vm, '2'));
    await vm.playSelected();
    await tick();
    expect(vm.resultStr, AppStrings.youLose);
    expect(vm.pointDelta, -10);
    expect(vm.resultDetails, [AppStrings.forbiddenFinish]);
  });

  test('手番の開始時に禁止あがりのカードだけなら強制的に負け', () async {
    final vm = await setup(
      ['3/D', '9/S', '9/H', 'K/C', '2/S'],
      ['7/D', '7/C', '8/S', 'J/C', 'A/H'],
    );
    vm.mainViewModel.setMyCards(hand(['A/C']));
    vm.mainViewModel.setCards1(hand(['2/C', '8/D']));
    vm.toggleSelectMyCard(find(vm, 'ACE'));
    // A を出すと上がりなので、先に相手の番にする
    vm.clearSelection();
    vm.mainViewModel.setMyCards(hand(['A/C', '3/H']));
    vm.toggleSelectMyCard(find(vm, '3', 'HEARTS'));
    await vm.playSelected();
    expect(vm.phase, DaifugoPhase.finished);
    expect(vm.message, AppStrings.forbiddenOnly(AppStrings.opponent));
    await tick();
    expect(vm.resultStr, AppStrings.youWin);
    expect(vm.pointDelta, 10);
  });

  test('革命が起きると残り枚数のポイントが 2 倍', () async {
    final vm = await setup(
      ['3/D', '9/S', '9/H', '9/C', '9/D'],
      ['7/D', '7/C', '8/S', 'J/C', 'A/H'],
    );
    vm.mainViewModel.setMyCards(hand(['9/S', '9/H', '9/C', '9/D']));
    for (final c in [...vm.myCardList]) {
      vm.toggleSelectMyCard(c);
    }
    await vm.playSelected();
    await tick();
    expect(vm.resultStr, AppStrings.youWin);
    expect(vm.pointDelta, 7 * 2);
    expect(vm.resultDetails, contains(AppStrings.revolutionBonus(1, 2)));
  });

  test('山札が足りないときは捨て札を戻してから引く', () async {
    final discards = hand(['4/H', '5/H', '6/H']);
    final api = FakeApiClient(deck: hand(['4/C', '4/D', '5/C', '5/D']), returnPool: discards);
    final vm = await setup(
      ['6/D', '6/S', '3/S', 'K/C', '2/S'],
      ['9/D', '9/C', '8/S', 'J/C', 'A/H'],
      api: api,
    );
    vm.mainViewModel.addDiscardedCards(discards);
    vm.mainViewModel.setMyCards(hand(['6/D', '6/S', '3/S']));
    vm.toggleSelectMyCard(find(vm, '6', 'DIAMONDS'));
    vm.toggleSelectMyCard(find(vm, '6', 'SPADES'));
    await vm.playSelected();
    expect(api.returnedCodes, discards.map((c) => c.code));
    expect(vm.mainViewModel.discardedCards, isEmpty);
    expect(vm.myCardList.length, 3);
    expect(vm.isDeckExhausted, isFalse);
  });

  test('捨て札を戻しても足りなければ山札切れ', () async {
    final vm = await setup(
      ['6/D', '6/S', '3/S', 'K/C', '2/S'],
      ['9/D', '9/C', '8/S', 'J/C', 'A/H'],
    );
    vm.mainViewModel.setMyCards(hand(['6/D', '6/S', '3/S']));
    vm.toggleSelectMyCard(find(vm, '6', 'DIAMONDS'));
    vm.toggleSelectMyCard(find(vm, '6', 'SPADES'));
    await vm.playSelected();
    expect(vm.isDeckExhausted, isTrue);
  });
}
