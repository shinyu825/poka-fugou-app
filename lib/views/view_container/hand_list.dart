import 'package:flutter/material.dart';
import 'package:poka_fugou_app/constants/strings.dart';
import 'package:poka_fugou_app/models/api/playing_card.dart';
import 'package:poka_fugou_app/views/view_container/card_image.dart';

/// ポーカーのハンド表示（自分の手札はタップで選択でき、選択中は少し浮く）
class HandList extends StatelessWidget {
  final List<PlayingCard> cardList;
  final bool isMyhand;

  /// 選択中のカード（自分の手札のみ）
  final List<PlayingCard> selectedCards;

  /// カードをタップしたとき（自分の手札のみ）
  final void Function(PlayingCard card)? onTapCard;

  const HandList({
    super.key,
    required this.cardList,
    this.isMyhand = false,
    this.selectedCards = const [],
    this.onTapCard,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final card in cardList)
                if (isMyhand)
                  Transform.translate(
                    offset: Offset(0, selectedCards.contains(card) ? -10 : 0),
                    child: GestureDetector(
                      onTap: () => onTapCard?.call(card),
                      child: CardImage(url: card.image),
                    ),
                  )
                else
                  const CardImage(url: AppStrings.cardBackUrl),
            ],
          ),
        ),
      ),
    );
  }
}
