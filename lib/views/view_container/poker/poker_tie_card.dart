import 'package:flutter/material.dart';
import 'package:poka_fugou_app/constants/strings.dart';
import 'package:poka_fugou_app/models/api/playing_card.dart';
import 'package:poka_fugou_app/views/view_container/card_image.dart';

/// サドンデスで引いたカード（表にするまでは裏向き。カードがなければ何も出さない）
class PokerTieCard extends StatelessWidget {
  final PlayingCard? card;
  final bool isOpen;

  const PokerTieCard({super.key, required this.card, required this.isOpen});

  @override
  Widget build(BuildContext context) {
    final card = this.card;
    if (card == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: CardImage(url: isOpen ? card.image : AppStrings.cardBackUrl),
    );
  }
}
