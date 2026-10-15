import 'package:flutter_test/flutter_test.dart';
import 'package:poka_fugou_app/models/api/playing_card.dart';
import 'package:poka_fugou_app/models/daifugo/daifugo_ai.dart';
import 'package:poka_fugou_app/models/daifugo/daifugo_player.dart';
import 'package:poka_fugou_app/models/daifugo/daifugo_rules.dart';
import 'package:poka_fugou_app/models/daifugo/daifugo_state.dart';

import 'helpers/test_cards.dart';

void main() {
  final ai = DaifugoAI();
  const me = DaifugoPlayer.me;
  const cpu = DaifugoPlayer.opponent;

  DaifugoState field(List<String> codes) =>
      DaifugoRules.play(const DaifugoState(turn: me), me, hand(codes)).state;

  List<String> values(Iterable<PlayingCard> cards) =>
      cards.map((c) => c.value).toList();

  group('出すカード', () {
    test('場が空なら一番弱い数字を、同じ数字はまとめて出す', () {
      final play = ai.choosePlay(
        hand(['3/S', '3/H', '9/D', 'K/C']),
        const DaifugoState(turn: cpu),
      );
      expect(values(play!), ['3', '3']);
    });
    test('場より強い中で一番弱いカードを出す', () {
      final play = ai.choosePlay(
        hand(['3/S', '9/D', 'K/C', '2/H']),
        field(['7/D']),
      );
      expect(values(play!), ['9']);
    });
    test('出せなければパス', () {
      final play = ai.choosePlay(hand(['3/S', '4/D']), field(['K/D']));
      expect(play, isNull);
    });
    test('ジョーカーは必要なときだけ使う', () {
      final play = ai.choosePlay(
        hand(['9/S', 'JOKER/B', 'A/D']),
        field(['7/D', '7/S']),
      );
      expect(values(play!), containsAll(['9', 'JOKER']));
    });
    test('禁止あがりのカードだけが残らないようにする', () {
      final play = ai.choosePlay(
        hand(['3/H', '2/H', '2/D']),
        const DaifugoState(turn: cpu),
      );
      expect(values(play!), ['2', '2']);
    });
    test('最後の 1 枚が禁止あがりになるなら、場にカードがあるうちはパス', () {
      final play = ai.choosePlay(hand(['2/H']), field(['K/D']));
      expect(play, isNull);
    });
    test('上がれるなら上がる', () {
      final play = ai.choosePlay(hand(['9/H']), field(['7/D']));
      expect(values(play!), ['9']);
    });
  });

  group('渡す・捨てる・ボンバー', () {
    test('渡すのは一番弱いカード', () {
      final give = ai.chooseGive(hand(['3/S', '9/D', 'K/C', 'JOKER/B']), 2);
      expect(values(give), ['3', '9']);
    });
    test('全部渡せるなら全部渡す（上がり）', () {
      final give = ai.chooseGive(hand(['K/C', '2/S']), 2);
      expect(give.length, 2);
    });
    test('禁止あがりのカードだけが残るなら、禁止カードを先に捨てる', () {
      final discard = ai.chooseDiscard(hand(['3/H', '2/H', '8/D']), 1);
      expect(values(discard), isNot(['3']));
    });
    test('ボンバーは自分の弱いカードの数字から選ぶ', () {
      final picked = ai.chooseBomberValues(
        hand(['4/S', '9/D', 'K/C']),
        2,
        isRevolution: false,
      );
      expect(picked, ['4', '9']);
    });
    test('ボンバーで Q とジョーカーは選ばない', () {
      final picked = ai.chooseBomberValues(
        hand(['Q/S', 'JOKER/B']),
        2,
        isRevolution: false,
      );
      expect(picked, isNot(contains('QUEEN')));
      expect(picked, isNot(contains('JOKER')));
      expect(picked.length, 2);
    });
  });
}
