import 'package:flutter_test/flutter_test.dart';
import 'package:poka_fugou_app/constants/strings.dart';
import 'package:poka_fugou_app/view_models/main_viewmodel.dart';
import 'package:poka_fugou_app/view_models/poker_viewmodel.dart';

import 'helpers/fake_api_client.dart';
import 'helpers/test_cards.dart';

void main() {
  PokerViewModel setup(
    List<String> mine,
    List<String> opponent, {
    FakeApiClient? api,
  }) {
    final main = MainViewModel(api: api)
      ..setMyCards(hand(mine))
      ..setCards1(hand(opponent));
    return PokerViewModel(main, api: api, resultDelay: Duration.zero);
  }

  /// 演出待ち（Duration.zero のタイマー）を進める
  Future<void> waitResult() => Future.delayed(Duration.zero);

  test('同じ数字でスート違いの手札はDRAW.になりサドンデスへ', () async {
    final vm = setup(
      ['9/S', '9/H', 'K/C', '3/D', '2/S'],
      ['9/D', '9/C', 'K/S', '3/C', '2/H'],
    );
    vm.resultHands();
    expect(vm.isWaiting, isTrue);
    await waitResult();
    expect(vm.isWaiting, isFalse);
    expect(vm.resultStr, AppStrings.draw);
    expect(vm.isTieBreak, isTrue);
    expect(vm.pointDelta, 0);
    vm.onResultDialogClosed();
    expect(vm.mainViewModel.myPoint, 0);
    expect(vm.myTieCard, isNull);
  });

  test('勝ったら役のポイントが加算される（ダイアログを閉じたとき）', () async {
    final vm = setup(
      ['9/S', '9/H', '9/C', '3/D', '2/S'],
      ['K/D', 'K/C', '8/S', '3/C', '2/H'],
    );
    vm.resultHands();
    await waitResult();
    expect(vm.resultStr, AppStrings.youWin);
    expect(vm.pointDelta, 3);
    expect(vm.myHandStr, 'スリーカード(9)');
    expect(vm.mainViewModel.myPoint, 0);
    vm.onResultDialogClosed();
    expect(vm.mainViewModel.myPoint, 3);
    expect(vm.mainViewModel.point1, -3);
    expect(vm.isExchanged, isTrue);
  });

  test('負けたら相手の役のポイントが減算される', () async {
    final vm = setup(
      ['9/S', '4/H', 'K/C', '3/D', '2/S'],
      ['K/D', 'K/C', '8/S', '3/C', '2/H'],
    );
    vm.resultHands();
    await waitResult();
    expect(vm.resultStr, AppStrings.youLose);
    expect(vm.pointDelta, -1);
    vm.onResultDialogClosed();
    expect(vm.mainViewModel.myPoint, -1);
  });

  test('サドンデスはジョーカーが最強', () async {
    final vm = setup(
      ['9/S', '9/H', 'K/C', '3/D', '2/S'],
      ['9/D', '9/C', 'K/S', '3/C', '2/H'],
    );
    vm.resultHands();
    await waitResult();
    vm.myTieCard = joker();
    vm.tieCard1 = card('ACE');
    vm.openTieBreakCards();
    expect(vm.isWaiting, isTrue);
    await waitResult();
    expect(vm.resultStr, AppStrings.youWin);
    expect(vm.isTieBreak, isFalse);
    expect(vm.pointDelta, 1);
    vm.onResultDialogClosed();
    expect(vm.mainViewModel.myPoint, 1);
    expect(vm.myHandStr, 'ワンペア(9) / 決着: JOKER');
    expect(vm.playerHandStr, 'ワンペア(9) / 決着: A');
  });

  group('カード交換（通信あり）', () {
    test('自分の選んだカードが捨て札になり、引いたカードに置き換わる', () async {
      final api = FakeApiClient(
        deck: hand(['A/S', 'A/H', '7/C', '6/D', '5/S']),
      );
      final vm = setup(
        ['9/S', '9/H', 'K/C', '3/D', '2/S'],
        ['Q/D', 'Q/C', '8/S', '4/C', '2/H'],
        api: api,
      );
      vm.toggleSelectMyCard(vm.myCardList[2]);
      vm.toggleSelectMyCard(vm.myCardList[3]);
      await vm.exchangeCard();
      await waitResult();

      final mine = vm.myCardList.map((c) => c.value).toList();
      expect(mine, containsAll(['9', '9', 'ACE', 'ACE', '2']));
      expect(
        vm.mainViewModel.discardedCards.map((c) => c.value),
        containsAll(['KING', '3']),
      );
      expect(vm.mainViewModel.remaining, lessThan(5));
      expect(vm.resultStr, AppStrings.youWin);
      expect(vm.myHandStr, 'ツーペア(A・9)');
    });

    test('通信に失敗したら手札はそのままで、もう一度交換できる', () async {
      final api = FakeApiClient(deck: hand(['A/S', 'A/H']), failAfter: 0);
      final vm = setup(
        ['9/S', '9/H', 'K/C', '3/D', '2/S'],
        ['Q/D', 'Q/C', '8/S', '4/C', '2/H'],
        api: api,
      );
      vm.toggleSelectMyCard(vm.myCardList[2]);
      await vm.exchangeCard();

      expect(vm.errorMessage, isNotNull);
      expect(vm.isJudging, isFalse);
      expect(vm.isLoading, isFalse);
      expect(vm.myCardList.map((c) => c.value).toList(), [
        '9',
        '9',
        'KING',
        '3',
        '2',
      ]);
      expect(vm.selectedMyCards.length, 1);
      expect(vm.resultStr, '');
    });
  });
}
