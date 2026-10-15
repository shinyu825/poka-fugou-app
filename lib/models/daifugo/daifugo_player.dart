/// 大富豪のプレイヤー（2 人対戦。人数を増やすときはここを拡張する）
enum DaifugoPlayer {
  me,
  opponent;

  /// 次の手番
  DaifugoPlayer get next => this == me ? opponent : me;
}
