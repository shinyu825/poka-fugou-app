import 'package:flutter/material.dart';
import 'package:poka_fugou_app/constants/strings.dart';
import 'package:poka_fugou_app/view_models/poker_viewmodel.dart';
import 'package:poka_fugou_app/views/view_container/card_image.dart';
import 'package:poka_fugou_app/views/view_container/hand_list.dart';
import 'package:poka_fugou_app/views/view_container/poker/poker_tie_card.dart';

/// 相手のエリア（ポイント・サドンデスカード・手札）
class PokerOpponentArea extends StatelessWidget {
  final PokerViewModel pokerViewModel;

  const PokerOpponentArea({super.key, required this.pokerViewModel});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(AppStrings.opponentPoint(pokerViewModel.point1)),
        const SizedBox(height: 10),
        PokerTieCard(
          card: pokerViewModel.tieCard1,
          isOpen: pokerViewModel.isTieCardsOpen,
        ),
        if (pokerViewModel.isOpenHands)
          // 判定後は役を作っているカードだけ表向き（残りは伏せたまま）
          SizedBox(
            height: 100,
            child: Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final card in pokerViewModel.cardList1)
                      CardImage(
                        url: pokerViewModel.openCards1.contains(card)
                            ? card.image
                            : AppStrings.cardBackUrl,
                      ),
                  ],
                ),
              ),
            ),
          )
        else
          // 判定前は裏向き
          HandList(cardList: pokerViewModel.cardList1),
      ],
    );
  }
}
