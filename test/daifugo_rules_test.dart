import 'package:flutter_test/flutter_test.dart';
import 'package:poka_fugou_app/models/api/playing_card.dart';
import 'package:poka_fugou_app/models/daifugo/daifugo_player.dart';
import 'package:poka_fugou_app/models/daifugo/daifugo_rules.dart';
import 'package:poka_fugou_app/models/daifugo/daifugo_state.dart';

import 'helpers/test_cards.dart';

void main() {
  const me = DaifugoPlayer.me;
  const cpu = DaifugoPlayer.opponent;

  /// 場にカードを順に出した状態を作る（自分 → 相手 → 自分 ... の順）
  DaifugoState field(List<List<String>> plays, {DaifugoState? from}) {
    var state = from ?? const DaifugoState(turn: me);
    var player = state.turn ?? me;
    for (final codes in plays) {
      state = DaifugoRules.play(state, player, hand(codes)).state;
      player = state.turn!;
    }
    return state;
  }

  bool can(List<String> codes, DaifugoState state) =>
      DaifugoRules.canPlay(hand(codes), state);

  group('出せるかの判定', () {
    test('場が空なら同じ数字の組み合わせは何でも出せる', () {
      const state = DaifugoState(turn: me);
      expect(can(['3/D'], state), isTrue);
      expect(can(['5/D', '5/S'], state), isTrue);
      expect(can(['5/D', 'JOKER/B'], state), isTrue);
      expect(can(['5/D', '6/S'], state), isFalse);
      expect(can([], state), isFalse);
    });
    test('場より強い数字だけ出せる（9 の場に 3・4 は出せない）', () {
      final state = field([
        ['9/D'],
      ]);
      expect(can(['3/H'], state), isFalse);
      expect(can(['4/S'], state), isFalse);
      expect(can(['9/S'], state), isFalse);
      expect(can(['10/S'], state), isTrue);
      expect(can(['2/S'], state), isTrue);
      expect(can(['JOKER/B'], state), isTrue);
    });
    test('枚数は場と同じでなければならない', () {
      final state = field([
        ['7/D', '7/S'],
      ]);
      expect(can(['9/S'], state), isFalse);
      expect(can(['6/S', '6/H'], state), isFalse);
      expect(can(['9/S', '9/H'], state), isTrue);
      expect(can(['9/S', 'JOKER/B'], state), isTrue);
      expect(can(['9/S', '9/H', '9/C'], state), isFalse);
    });
    test('2 が一番強く、ジョーカーはさらに強い', () {
      final state = field([
        ['2/D'],
      ]);
      expect(can(['A/S'], state), isFalse);
      expect(can(['JOKER/B'], state), isTrue);
    });
    test('ジョーカーだけの場にはジョーカーだけは出せない。スペ 3 は出せる', () {
      final state = field([
        ['JOKER/B'],
      ]);
      expect(can(['JOKER/R'], state), isFalse);
      expect(can(['2/S'], state), isFalse);
      expect(can(['3/S'], state), isTrue);
      expect(can(['3/D'], state), isFalse);
    });
    test('スペ 3 返しはジョーカー 1 枚のときだけ', () {
      final state = field([
        ['JOKER/B', 'JOKER/R'],
      ]);
      expect(can(['3/S', '3/D'], state), isFalse);
    });
  });

  group('革命と J バック', () {
    test('4 枚出すと革命になり、強さが逆になる', () {
      final state = field([
        ['9/S', '9/H', '9/D', '9/C'],
      ]);
      expect(state.isRevolution, isTrue);
      expect(state.revolutionCount, 1);
      expect(state.turn, cpu);
      final next = field([
        ['6/D'],
      ], from: state);
      expect(can(['3/H'], next), isTrue);
      expect(can(['7/S'], next), isFalse);
      expect(can(['JOKER/B'], next), isTrue);
    });
    test('ジョーカー入りの 4 枚も革命。革命返しで元に戻り回数は 2', () {
      final state = field([
        ['9/S', '9/H', '9/D', 'JOKER/B'],
        ['K/S', 'K/H', 'K/D', 'K/C'],
      ]);
      // 革命中は K が 9 より弱いので出せない。出せるのは 3〜8
      expect(state.isRevolution, isFalse);
      expect(state.revolutionCount, 2);
    });
    test('革命中に 4 枚出すには弱い数字が必要', () {
      final state = field([
        ['9/S', '9/H', '9/D', '9/C'],
      ]);
      expect(can(['K/S', 'K/H', 'K/D', 'K/C'], state), isFalse);
      expect(can(['5/S', '5/H', '5/D', '5/C'], state), isTrue);
    });
    test('J バックは場が流れるまで逆になる', () {
      final state = field([
        ['J/D'],
      ]);
      expect(state.isBack, isTrue);
      expect(can(['10/S'], state), isTrue);
      expect(can(['Q/S'], state), isFalse);
      final flowed = DaifugoRules.pass(state, cpu);
      expect(flowed.isBack, isFalse);
      expect(flowed.isFieldEmpty, isTrue);
      expect(flowed.turn, me);
    });
    test('革命中の J バックは通常の順に戻る', () {
      final state = field([
        ['9/S', '9/H', '9/D', '9/C'],
        ['J/D', 'J/S', 'J/H', 'J/C'],
      ]);
      // J 4 枚なので革命返しにもなる（革命なし + バック = 逆順）
      expect(state.isRevolution, isFalse);
      expect(state.isBack, isTrue);
      expect(state.isReversed, isTrue);
    });
  });

  group('縛り', () {
    test('同じスートが 2 回続くと縛り', () {
      final state = field([
        ['4/D'],
        ['7/D'],
      ]);
      expect(state.lockedSuits, {'DIAMONDS'});
      expect(can(['9/S'], state), isFalse);
      expect(can(['9/D'], state), isTrue);
      expect(can(['JOKER/B'], state), isTrue);
    });
    test('複数枚は全部のスートが合わないと縛りにならない', () {
      final state = field([
        ['6/D', '6/H'],
        ['9/D', '9/S'],
      ]);
      expect(state.lockedSuits, isNull);
      expect(state.isNumberLocked, isFalse);
    });
    test('数字がちょうど 1 つ上で続くと数縛り', () {
      final state = field([
        ['6/D', '6/H'],
        ['7/S', '7/D'],
      ]);
      expect(state.lockedSuits, isNull);
      expect(state.isNumberLocked, isTrue);
      expect(can(['8/S', '8/C'], state), isTrue);
      expect(can(['9/S', '9/C'], state), isFalse);
    });
    test('スートと数字の両方が続くと激縛り', () {
      final state = field([
        ['6/D', '6/H'],
        ['7/D', '7/H'],
      ]);
      expect(state.lockedSuits, {'DIAMONDS', 'HEARTS'});
      expect(state.isNumberLocked, isTrue);
      expect(can(['8/D', '8/H'], state), isTrue);
      expect(can(['8/D', '8/S'], state), isFalse);
      expect(can(['9/D', '9/H'], state), isFalse);
    });
    test('ジョーカー入りはスート縛りにならず、数縛りだけになる', () {
      final state = field([
        ['3/D', '3/H'],
        ['4/D', 'JOKER/B'],
      ]);
      expect(state.lockedSuits, isNull);
      expect(state.isNumberLocked, isTrue);
      expect(can(['5/D', '5/H'], state), isTrue);
      expect(can(['6/D', '6/H'], state), isFalse);
      // 5 は 2 人だと場が流れるので、流れない数字で続きを確認する
      final later = field([
        ['9/D', '9/H'],
        ['10/D', 'JOKER/B'],
      ]);
      final next = field([
        ['J/D', 'J/H'],
      ], from: later);
      expect(next.lockedSuits, isNull);
      expect(next.isNumberLocked, isTrue);
    });
    test('10 → J で数縛りになり、J バックで次は 10 → 9', () {
      final state = field([
        ['10/D'],
        ['J/S'],
      ]);
      expect(state.isNumberLocked, isTrue);
      expect(state.isBack, isTrue);
      expect(can(['10/S'], state), isTrue);
      expect(can(['9/S'], state), isFalse);
      final next = field([
        ['10/H'],
      ], from: state);
      expect(can(['9/D'], next), isTrue);
      expect(can(['8/D'], next), isFalse);
    });
    test('8 切りやパスで縛りは解除される', () {
      final locked = field([
        ['4/D'],
        ['7/D'],
      ]);
      final cut = field([
        ['8/D'],
      ], from: locked);
      expect(cut.lockedSuits, isNull);
      expect(cut.isFieldEmpty, isTrue);
      expect(cut.turn, me);
    });
  });

  group('カードの効果', () {
    test('5 は 2 人なら一周して場が流れ、自分の番', () {
      final outcome = DaifugoRules.play(
        const DaifugoState(turn: me),
        me,
        hand(['5/D']),
      );
      expect(outcome.effect, CardEffect.skip);
      expect(outcome.flowed, isTrue);
      expect(outcome.state.turn, me);
    });
    test('8 は場が流れて同じ人から', () {
      final outcome = DaifugoRules.play(
        field([
          ['5/D'],
        ]),
        cpu,
        hand(['8/D']),
      );
      expect(outcome.effect, CardEffect.cut);
      expect(outcome.flowed, isTrue);
      expect(outcome.state.turn, cpu);
    });
    test('スペ 3 返しで場が流れて出した人から', () {
      final outcome = DaifugoRules.play(
        field([
          ['JOKER/B'],
        ]),
        cpu,
        hand(['3/S']),
      );
      expect(outcome.spadeThree, isTrue);
      expect(outcome.flowed, isTrue);
      expect(outcome.state.turn, cpu);
    });
    test('7 + ジョーカーは 2 枚分の効果', () {
      final outcome = DaifugoRules.play(
        const DaifugoState(turn: me),
        me,
        hand(['7/D', 'JOKER/B']),
      );
      expect(outcome.effect, CardEffect.pass);
      expect(outcome.count, 2);
      expect(outcome.state.turn, cpu);
    });
    test('効果の対応表', () {
      expect(DaifugoRules.effectOf(hand(['6/D'])), CardEffect.draw);
      expect(DaifugoRules.effectOf(hand(['10/D'])), CardEffect.discard);
      expect(DaifugoRules.effectOf(hand(['Q/D'])), CardEffect.bomber);
      expect(DaifugoRules.effectOf(hand(['J/D'])), CardEffect.back);
      expect(DaifugoRules.effectOf(hand(['9/D'])), isNull);
      expect(DaifugoRules.effectOf(hand(['JOKER/B'])), isNull);
    });
  });

  group('禁止あがり', () {
    test('2・8・ジョーカー・スペ 3 で上がるのは禁止', () {
      bool forbidden(List<String> codes, {bool rev = false}) =>
          DaifugoRules.isForbiddenFinish(hand(codes), isRevolution: rev);
      expect(forbidden(['2/D']), isTrue);
      expect(forbidden(['8/D']), isTrue);
      expect(forbidden(['JOKER/B']), isTrue);
      expect(forbidden(['3/S']), isTrue);
      expect(forbidden(['3/D']), isFalse);
      expect(forbidden(['7/D', 'JOKER/B']), isFalse);
      expect(forbidden(['3/D', 'JOKER/B']), isFalse);
      expect(forbidden(['2/D', '2/S', '2/H', '2/C']), isTrue);
    });
    test('革命中は 3・8・ジョーカーが禁止で 2 は出せる', () {
      bool forbidden(List<String> codes) =>
          DaifugoRules.isForbiddenFinish(hand(codes), isRevolution: true);
      expect(forbidden(['3/D']), isTrue);
      expect(forbidden(['3/D', '3/H', '3/S', '3/C']), isTrue);
      expect(forbidden(['2/D']), isFalse);
      expect(forbidden(['8/D']), isTrue);
    });
    test('手札が禁止あがりのカードだけか', () {
      expect(
        DaifugoRules.isAllForbidden(hand(['2/D', '8/S']), isRevolution: false),
        isTrue,
      );
      expect(
        DaifugoRules.isAllForbidden(hand(['2/D', '5/S']), isRevolution: false),
        isFalse,
      );
      expect(DaifugoRules.isAllForbidden([], isRevolution: false), isFalse);
    });
  });

  group('出せる組み合わせと選べるカード', () {
    test('場が 9 なら 3・4 は選べない', () {
      final state = field([
        ['9/D'],
      ]);
      final cards = hand(['3/H', '4/S', '10/S', '10/H', 'JOKER/B']);
      final selectable = DaifugoRules.selectableCards(cards, [], state);
      expect(selectable.map((c) => c.value).toSet(), {'10', 'JOKER'});
    });
    test('場が 7 のペアなら 1 枚や 7 以下は選べない', () {
      final state = field([
        ['7/D', '7/S'],
      ]);
      final cards = hand(['6/S', '6/H', '9/S', '9/H', '10/S', 'JOKER/B']);
      final selectable = DaifugoRules.selectableCards(cards, [], state);
      // 10 はジョーカーと組めば出せる
      expect(selectable.map((c) => c.value).toSet(), {'9', '10', 'JOKER'});
      // 9 を選んだら 10 は選べない
      final nine = cards.firstWhere((c) => c.value == '9');
      final after = DaifugoRules.selectableCards(cards, [nine], state);
      expect(after.map((c) => c.value).toSet(), {'9', 'JOKER'});
    });
    test('縛り中は縛りに合うカードだけ選べる', () {
      final state = field([
        ['4/D'],
        ['7/D'],
      ]);
      final cards = hand(['9/S', '9/D', 'K/H']);
      final selectable = DaifugoRules.selectableCards(cards, [], state);
      expect(selectable.map((c) => c.code).toSet(), {'9/DIAMONDS'});
    });
    test('禁止あがりのカードも選べる（上がり放棄になるだけ）', () {
      final state = field([
        ['9/D'],
      ]);
      final selectable = DaifugoRules.selectableCards(hand(['2/S']), [], state);
      expect(selectable.length, 1);
    });
  });

  test('強さの計算（革命中は逆、ジョーカーは常に最強）', () {
    expect(
      DaifugoRules.strength(parseDaifugoRank('2'), isReversed: false),
      greaterThan(DaifugoRules.strength(parseDaifugoRank('3'), isReversed: false)),
    );
    expect(
      DaifugoRules.strength(parseDaifugoRank('3'), isReversed: true),
      greaterThan(DaifugoRules.strength(parseDaifugoRank('2'), isReversed: true)),
    );
    expect(
      DaifugoRules.strength(DaifugoRules.jokerRank, isReversed: true),
      greaterThan(DaifugoRules.strength(parseDaifugoRank('3'), isReversed: true)),
    );
  });
}
