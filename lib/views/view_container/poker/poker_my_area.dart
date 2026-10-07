import 'package:flutter/material.dart';
import 'package:poka_fugou_app/constants/strings.dart';
import 'package:poka_fugou_app/view_models/poker_viewmodel.dart';
import 'package:poka_fugou_app/views/view_container/hand_list.dart';
import 'package:poka_fugou_app/views/view_container/poker/poker_tie_card.dart';

/// 自分のエリア（手札・サドンデスカード・ポイント）
class PokerMyArea extends StatelessWidget {
  final PokerViewModel pokerViewModel;

  const PokerMyArea({super.key, required this.pokerViewModel});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        HandList(
          cardList: pokerViewModel.myCardList,
          isMyhand: true,
          selectedCards: pokerViewModel.selectedMyCards,
          onTapCard: pokerViewModel.toggleSelectMyCard,
        ),
        PokerTieCard(
          card: pokerViewModel.myTieCard,
          isOpen: pokerViewModel.isTieCardsOpen,
        ),
        const SizedBox(height: 10),
        Text(AppStrings.myPoint(pokerViewModel.myPoint)),
      ],
    );
  }
}
