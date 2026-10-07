import 'package:flutter/material.dart';
import 'package:poka_fugou_app/constants/strings.dart';
import 'package:poka_fugou_app/models/api/playing_card.dart';
import 'package:poka_fugou_app/views/view_container/card_image.dart';

/// 大富豪のハンド（重ねて表示。自分の手札はタップで選択でき、選択中は少し浮く）
class DaifugoHandList extends StatelessWidget {
  final List<PlayingCard> cardList;
  final bool isMyhand;

  /// 選択中のカード（自分の手札のみ）
  final List<PlayingCard> selectedCards;

  /// カードをタップしたとき（自分の手札のみ）
  final void Function(PlayingCard card)? onTapCard;

  const DaifugoHandList({
    super.key,
    required this.cardList,
    this.isMyhand = false,
    this.selectedCards = const [],
    this.onTapCard,
  });

  static const double _cardHeight = 100;
  static const double _cardWidth = 72;

  /// カードの重なり具合（数値が大きいほど重なる）
  static const double _overlapOffset = 30;

  @override
  Widget build(BuildContext context) {
    final cardCount = cardList.length;
    final totalWidth = cardCount == 0
        ? 0.0
        : _cardWidth + _overlapOffset * (cardCount - 1);

    return SizedBox(
      height: _cardHeight,
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: totalWidth,
            height: _cardHeight,
            child: Stack(
              children: [
                for (int index = 0; index < cardCount; index++)
                  Positioned(
                    left: index * _overlapOffset,
                    child: _card(cardList[index]),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _card(PlayingCard card) {
    final image = CardImage(
      url: isMyhand ? card.image : AppStrings.cardBackUrl,
    );
    if (!isMyhand) return image;
    return Transform.translate(
      offset: Offset(0, selectedCards.contains(card) ? -10 : 0),
      child: GestureDetector(onTap: () => onTapCard?.call(card), child: image),
    );
  }
}
