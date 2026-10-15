import 'package:poka_fugou_app/models/api/playing_card.dart';
import 'package:poka_fugou_app/models/daifugo/daifugo_rules.dart';
import 'package:poka_fugou_app/models/daifugo/daifugo_state.dart';

/// 大富豪の CPU の思考
///
/// 出せる中で一番弱い組み合わせを出す。渡す・捨てる・ボンバーも一番弱いカードから。
/// 禁止あがりのカードだけが手札に残らないようにする
class DaifugoAI {
  static const double _forbiddenFinishPenalty = 1000;
  static const double _finishBonus = -1000;
  static const double _allForbiddenPenalty = 500;
  static const double _jokerPenalty = 30;

  /// 出すカード（出せない・出さない方がよいときは null = パス）
  List<PlayingCard>? choosePlay(List<PlayingCard> hand, DaifugoState state) {
    final plays = DaifugoRules.validPlays(hand, state);
    if (plays.isEmpty) return null;
    List<PlayingCard>? best;
    var bestScore = double.infinity;
    for (final play in plays) {
      final score = _playScore(play, hand, state);
      if (score < bestScore) {
        best = play;
        bestScore = score;
      }
    }
    // 禁止あがりになる手しかなければ、場にカードがあるうちはパス
    if (bestScore >= _forbiddenFinishPenalty && !state.isFieldEmpty) {
      return null;
    }
    return best;
  }

  /// 7 で渡すカード（出した枚数分。全部渡せるなら上がり）
  List<PlayingCard> chooseGive(List<PlayingCard> hand, int count) =>
      _chooseWeakest(hand, count);

  /// 10 で捨てるカード
  List<PlayingCard> chooseDiscard(List<PlayingCard> hand, int count) =>
      _chooseWeakest(hand, count);

  /// Q ボンバーで選ぶ数字（自分の弱いカードの数字から）
  List<String> chooseBomberValues(
    List<PlayingCard> hand,
    int count, {
    required bool isRevolution,
  }) {
    int strengthOf(String value) => DaifugoRules.strength(
      parseDaifugoRank(value),
      isReversed: isRevolution,
    );
    final own = {
      for (final c in hand)
        if (!c.isJoker && c.value != 'QUEEN') c.value,
    }.toList()..sort((a, b) => strengthOf(a).compareTo(strengthOf(b)));
    final others = DaifugoRules.bomberValues.where((v) => !own.contains(v)).toList()
      ..sort((a, b) => strengthOf(a).compareTo(strengthOf(b)));

    final picked = <String>[];
    for (final value in [...own, ...others]) {
      if (picked.length >= count) break;
      final remaining = hand
          .where((c) => c.value != value && !picked.contains(c.value))
          .toList();
      if (DaifugoRules.isAllForbidden(remaining, isRevolution: isRevolution)) {
        continue;
      }
      picked.add(value);
    }
    for (final value in [...own, ...others]) {
      if (picked.length >= count) break;
      if (!picked.contains(value)) picked.add(value);
    }
    return picked;
  }

  double _playScore(
    List<PlayingCard> play,
    List<PlayingCard> hand,
    DaifugoState state,
  ) {
    final remaining = hand.where((c) => !play.contains(c)).toList();
    var score = 0.0;
    if (remaining.isEmpty) {
      score += DaifugoRules.isForbiddenFinish(
            play,
            isRevolution: state.isRevolution,
          )
          ? _forbiddenFinishPenalty
          : _finishBonus;
    } else if (DaifugoRules.isAllForbidden(
      remaining,
      isRevolution: state.isRevolution,
    )) {
      score += _allForbiddenPenalty;
    }
    final rank = DaifugoRules.groupRank(play) ?? DaifugoRules.jokerRank;
    score += DaifugoRules.strength(rank, isReversed: state.isReversed) * 10;
    score -= play.length;
    if (rank != DaifugoRules.jokerRank) {
      score += play.where((c) => c.isJoker).length * _jokerPenalty;
    }
    return score;
  }

  /// 弱いカードから [count] 枚（手札が足りなければ全部）
  List<PlayingCard> _chooseWeakest(List<PlayingCard> hand, int count) {
    if (hand.length <= count) return [...hand];
    List<PlayingCard>? best;
    var bestScore = double.infinity;
    for (final combo in _combinations(hand, count)) {
      final remaining = hand.where((c) => !combo.contains(c)).toList();
      var score = 0.0;
      // 革命は渡す側に関係ないので通常の強さで判断する
      if (DaifugoRules.isAllForbidden(remaining, isRevolution: false)) {
        score += _allForbiddenPenalty;
      }
      for (final c in combo) {
        score += DaifugoRules.strength(
          DaifugoRules.rankOf(c),
          isReversed: false,
        );
      }
      if (score < bestScore) {
        best = combo;
        bestScore = score;
      }
    }
    return best ?? [];
  }

  Iterable<List<PlayingCard>> _combinations(
    List<PlayingCard> cards,
    int count, [
    int start = 0,
  ]) sync* {
    if (count == 0) {
      yield [];
      return;
    }
    for (int i = start; i <= cards.length - count; i++) {
      for (final rest in _combinations(cards, count - 1, i + 1)) {
        yield [cards[i], ...rest];
      }
    }
  }
}
