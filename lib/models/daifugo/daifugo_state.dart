import 'package:poka_fugou_app/models/daifugo/daifugo_player.dart';
import 'package:poka_fugou_app/models/daifugo/field_play.dart';

/// 大富豪の進行状態（変更は copyWith で新しい状態を作る）
class DaifugoState {
  /// 場に出ているカード（流れてからの履歴。最後が一番上）
  final List<FieldPlay> fieldPlays;

  /// 革命中かどうか
  final bool isRevolution;

  /// 革命が起きた回数（ポイントの倍率に使う）
  final int revolutionCount;

  /// J バック中かどうか（場が流れるまで）
  final bool isBack;

  /// 縛り中のスート（null なら縛りなし）
  final Set<String>? lockedSuits;

  /// 数縛り中かどうか
  final bool isNumberLocked;

  /// 手番（開始前は null）
  final DaifugoPlayer? turn;

  const DaifugoState({
    this.fieldPlays = const [],
    this.isRevolution = false,
    this.revolutionCount = 0,
    this.isBack = false,
    this.lockedSuits,
    this.isNumberLocked = false,
    this.turn,
  });

  /// 場の一番上
  FieldPlay? get top => fieldPlays.isEmpty ? null : fieldPlays.last;

  bool get isFieldEmpty => fieldPlays.isEmpty;

  /// 強さの順が逆になっているか（革命と J バックは打ち消し合う）
  bool get isReversed => isRevolution != isBack;

  /// 数縛りで次に求められるランクの向き
  int get direction => isReversed ? -1 : 1;

  DaifugoState copyWith({
    List<FieldPlay>? fieldPlays,
    bool? isRevolution,
    int? revolutionCount,
    bool? isBack,
    Set<String>? lockedSuits,
    bool clearLockedSuits = false,
    bool? isNumberLocked,
    DaifugoPlayer? turn,
  }) {
    return DaifugoState(
      fieldPlays: fieldPlays ?? this.fieldPlays,
      isRevolution: isRevolution ?? this.isRevolution,
      revolutionCount: revolutionCount ?? this.revolutionCount,
      isBack: isBack ?? this.isBack,
      lockedSuits: clearLockedSuits ? null : (lockedSuits ?? this.lockedSuits),
      isNumberLocked: isNumberLocked ?? this.isNumberLocked,
      turn: turn ?? this.turn,
    );
  }

  /// 場が流れた状態（縛り・J バックも解除。革命は続く）
  DaifugoState flowed() => copyWith(
    fieldPlays: const [],
    isBack: false,
    isNumberLocked: false,
    clearLockedSuits: true,
  );
}
