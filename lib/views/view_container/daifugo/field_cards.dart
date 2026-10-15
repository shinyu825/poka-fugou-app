import 'package:flutter/material.dart';
import 'package:poka_fugou_app/models/daifugo/field_play.dart';
import 'package:poka_fugou_app/views/view_container/card_image.dart';

/// 場のカード（新しいものほど少し下にずらして重ね、前に出したカードの上部が見える）
class FieldCards extends StatelessWidget {
  final List<FieldPlay> plays;

  const FieldCards({super.key, required this.plays});

  static const double _cardWidth = 72;
  static const double _cardHeight = 100;

  /// 同時に出したカードの横の重なり
  static const double _overlapX = 24;

  /// 前に出したカードとの縦のずれ
  static const double _offsetY = 18;

  /// 表示する回数（古いものから消える）
  static const int _maxShown = 4;

  @override
  Widget build(BuildContext context) {
    final shown = plays.length > _maxShown
        ? plays.sublist(plays.length - _maxShown)
        : plays;
    var width = _cardWidth;
    for (final play in shown) {
      final w = _cardWidth + _overlapX * (play.cards.length - 1);
      if (w > width) width = w;
    }
    final height =
        _cardHeight + _offsetY * (shown.isEmpty ? 0 : shown.length - 1);

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          for (int i = 0; i < shown.length; i++)
            Positioned(
              top: i * _offsetY,
              left: 0,
              child: _play(shown[i]),
            ),
        ],
      ),
    );
  }

  Widget _play(FieldPlay play) {
    final cards = play.cards;
    return SizedBox(
      width: _cardWidth + _overlapX * (cards.length - 1),
      height: _cardHeight,
      child: Stack(
        children: [
          for (int i = 0; i < cards.length; i++)
            Positioned(
              left: i * _overlapX,
              child: CardImage(url: cards[i].image),
            ),
        ],
      ),
    );
  }
}
