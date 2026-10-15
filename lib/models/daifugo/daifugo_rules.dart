import 'package:poka_fugou_app/models/api/playing_card.dart';
import 'package:poka_fugou_app/models/daifugo/daifugo_player.dart';
import 'package:poka_fugou_app/models/daifugo/daifugo_state.dart';
import 'package:poka_fugou_app/models/daifugo/field_play.dart';

/// カードの効果
enum CardEffect {
  /// 5: 出した枚数分プレイヤーを飛ばす
  skip,

  /// 6: 出した本人が枚数分引く
  draw,

  /// 7: 枚数まで次のプレイヤーに渡す
  pass,

  /// 8: 場が流れて同じ人から
  cut,

  /// 10: 枚数まで捨てる
  discard,

  /// J: 流れるまで強さが逆
  back,

  /// Q: 枚数分の数字を選んで捨てさせる
  bomber,
}

/// カードを出した結果
class PlayOutcome {
  final DaifugoState state;

  /// 場が流れたか
  final bool flowed;

  /// 発動した効果（ジョーカーだけ・効果なしのカードは null）
  final CardEffect? effect;

  /// 出した枚数（効果の回数）
  final int count;

  /// 革命が起きたか
  final bool revolution;

  /// スペ 3 返しか
  final bool spadeThree;

  /// 流れる前の場（出したカードを含む。流れたときに見せるため）
  final List<FieldPlay> playsBeforeFlow;

  const PlayOutcome({
    required this.state,
    required this.flowed,
    required this.effect,
    required this.count,
    required this.revolution,
    required this.spadeThree,
    required this.playsBeforeFlow,
  });
}

/// 大富豪のルール判定（状態を持たない）
class DaifugoRules {
  static const int jokerRank = 16;

  /// 革命・J バックに関係なく、常に最強
  static const int _jokerStrength = 100;

  /// 何人で遊ぶか
  static const int playerCount = 2;

  /// Q ボンバーで選べる数字（Q とジョーカーは選べない）
  static const List<String> bomberValues = [
    '2',
    'ACE',
    'KING',
    'JACK',
    '10',
    '9',
    '8',
    '7',
    '6',
    '5',
    '4',
    '3',
  ];

  static int rankOf(PlayingCard card) => parseDaifugoRank(card.value);

  static bool isSpadeThree(PlayingCard card) =>
      card.value == '3' && card.suit == 'SPADES';

  /// 強さ（大きいほど強い）
  static int strength(int rank, {required bool isReversed}) {
    if (rank == jokerRank) return _jokerStrength;
    return isReversed ? jokerRank - rank : rank;
  }

  /// ジョーカー以外が同じランクか
  static bool isValidGroup(List<PlayingCard> cards) {
    if (cards.isEmpty) return false;
    final ranks = {
      for (final c in cards)
        if (!c.isJoker) rankOf(c),
    };
    return ranks.length <= 1;
  }

  /// ジョーカー以外のランク（ジョーカーだけなら null）
  static int? groupRank(List<PlayingCard> cards) {
    for (final c in cards) {
      if (!c.isJoker) return rankOf(c);
    }
    return null;
  }

  static CardEffect? effectOf(List<PlayingCard> cards) {
    for (final c in cards) {
      if (c.isJoker) continue;
      switch (c.value) {
        case '5':
          return CardEffect.skip;
        case '6':
          return CardEffect.draw;
        case '7':
          return CardEffect.pass;
        case '8':
          return CardEffect.cut;
        case '10':
          return CardEffect.discard;
        case 'JACK':
          return CardEffect.back;
        case 'QUEEN':
          return CardEffect.bomber;
        default:
          return null;
      }
    }
    return null;
  }

  /// 禁止あがりのカードか（2・8・ジョーカー・スペ 3。革命中は 3・8・ジョーカー・スペ 3）
  static bool isForbiddenCard(PlayingCard card, {required bool isRevolution}) {
    if (card.isJoker || isSpadeThree(card)) return true;
    if (card.value == '8') return true;
    return isRevolution ? card.value == '3' : card.value == '2';
  }

  /// 手札が禁止あがりのカードだけか（空なら false）
  static bool isAllForbidden(
    List<PlayingCard> hand, {
    required bool isRevolution,
  }) {
    return hand.isNotEmpty &&
        hand.every((c) => isForbiddenCard(c, isRevolution: isRevolution));
  }

  /// このカードで上がると禁止あがりか（ジョーカーは一緒に出したカードの扱い）
  static bool isForbiddenFinish(
    List<PlayingCard> cards, {
    required bool isRevolution,
  }) {
    if (cards.every((c) => c.isJoker)) return true;
    return cards.any(
      (c) => !c.isJoker && isForbiddenCard(c, isRevolution: isRevolution),
    );
  }

  /// スペ 3 返しか（場のジョーカー 1 枚に対してスペ 3 を 1 枚）
  static bool isSpadeThreeReturn(List<PlayingCard> cards, DaifugoState state) {
    final top = state.top;
    return top != null &&
        top.cards.length == 1 &&
        top.isJokerOnly &&
        cards.length == 1 &&
        isSpadeThree(cards.first);
  }

  /// 今の場に出せるか
  static bool canPlay(List<PlayingCard> cards, DaifugoState state) {
    if (!isValidGroup(cards)) return false;
    final top = state.top;
    if (top == null) return true;
    if (cards.length != top.cards.length) return false;
    if (isSpadeThreeReturn(cards, state)) return true;

    final rank = groupRank(cards);
    final isReversed = state.isReversed;
    if (rank == null) {
      // ジョーカーだけはジョーカーだけの場には出せない
      if (top.isJokerOnly) return false;
    } else if (strength(rank, isReversed: isReversed) <=
        strength(top.rank, isReversed: isReversed)) {
      return false;
    }

    final lockedSuits = state.lockedSuits;
    if (lockedSuits != null) {
      final suits = {
        for (final c in cards)
          if (!c.isJoker) c.suit,
      };
      if (!lockedSuits.containsAll(suits)) return false;
    }
    if (state.isNumberLocked && rank != null) {
      if (rank != top.rank + state.direction) return false;
    }
    return true;
  }

  /// カードを出したあとの状態と効果（手札の増減は呼び出し側で行う）
  static PlayOutcome play(
    DaifugoState state,
    DaifugoPlayer player,
    List<PlayingCard> cards,
  ) {
    final top = state.top;
    final rank = groupRank(cards);
    final int effectiveRank;
    if (rank != null) {
      effectiveRank = rank;
    } else if (top != null && state.isNumberLocked) {
      effectiveRank = top.rank + state.direction;
    } else {
      effectiveRank = jokerRank;
    }

    // 縛りの判定（直前と同じスート / 数字が続いたら）
    var lockedSuits = state.lockedSuits;
    var isNumberLocked = state.isNumberLocked;
    final hasJoker = cards.any((c) => c.isJoker);
    if (top != null) {
      final suits = {
        for (final c in cards)
          if (!c.isJoker) c.suit,
      };
      if (lockedSuits == null &&
          !top.hasJoker &&
          !hasJoker &&
          top.suits.length == suits.length &&
          top.suits.containsAll(suits)) {
        lockedSuits = suits;
      }
      if (!isNumberLocked &&
          rank != null &&
          !top.isJokerOnly &&
          rank == top.rank + state.direction) {
        isNumberLocked = true;
      }
    }

    final play = FieldPlay(cards: cards, player: player, rank: effectiveRank);
    var next = state.copyWith(
      fieldPlays: [...state.fieldPlays, play],
      lockedSuits: lockedSuits,
      isNumberLocked: isNumberLocked,
    );

    final revolution = cards.length >= 4;
    if (revolution) {
      next = next.copyWith(
        isRevolution: !next.isRevolution,
        revolutionCount: next.revolutionCount + 1,
      );
    }

    final effect = effectOf(cards);
    final spadeThree = isSpadeThreeReturn(cards, state);
    var flowed = false;
    var turn = player.next;
    switch (effect) {
      case CardEffect.back:
        next = next.copyWith(isBack: !next.isBack);
      case CardEffect.cut:
        flowed = true;
        turn = player;
      case CardEffect.skip:
        // 一周以上したら場が流れて自分の番
        if (cards.length >= playerCount - 1) {
          flowed = true;
          turn = player;
        }
      default:
        break;
    }
    if (spadeThree) {
      flowed = true;
      turn = player;
    }
    final playsBeforeFlow = next.fieldPlays;
    if (flowed) next = next.flowed();
    next = next.copyWith(turn: turn);

    return PlayOutcome(
      state: next,
      flowed: flowed,
      effect: effect,
      count: cards.length,
      revolution: revolution,
      spadeThree: spadeThree,
      playsBeforeFlow: playsBeforeFlow,
    );
  }

  /// パスしたあとの状態（場が流れて相手の番）
  static DaifugoState pass(DaifugoState state, DaifugoPlayer player) {
    return state.flowed().copyWith(turn: player.next);
  }

  /// 手札から出せる組み合わせをすべて返す
  static List<List<PlayingCard>> validPlays(
    List<PlayingCard> hand,
    DaifugoState state,
  ) {
    final jokers = hand.where((c) => c.isJoker).toList();
    final groups = <int, List<PlayingCard>>{};
    for (final c in hand) {
      if (c.isJoker) continue;
      groups.putIfAbsent(rankOf(c), () => []).add(c);
    }
    final jokerSubsets = _subsets(jokers);
    final plays = <List<PlayingCard>>[];
    for (final group in groups.values) {
      for (final sub in _subsets(group)) {
        if (sub.isEmpty) continue;
        for (final js in jokerSubsets) {
          plays.add([...sub, ...js]);
        }
      }
    }
    for (final js in jokerSubsets) {
      if (js.isNotEmpty) plays.add(js);
    }
    return plays.where((p) => canPlay(p, state)).toList();
  }

  /// 選択中のカードに加えて選べるカード（選択中のカードも含む）
  static Set<PlayingCard> selectableCards(
    List<PlayingCard> hand,
    List<PlayingCard> selected,
    DaifugoState state,
  ) {
    final plays = validPlays(hand, state).where(
      (p) => selected.every(p.contains),
    );
    return {for (final p in plays) ...p};
  }

  static List<List<PlayingCard>> _subsets(List<PlayingCard> cards) {
    var result = <List<PlayingCard>>[[]];
    for (final c in cards) {
      result = [
        ...result,
        for (final r in result) [...r, c],
      ];
    }
    return result;
  }
}
