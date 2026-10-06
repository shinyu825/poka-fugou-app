import 'package:flutter/material.dart';
import 'package:poka_fugou_app/constants/strings.dart';
import 'package:poka_fugou_app/models/api/playing_card.dart';
import 'package:poka_fugou_app/view_models/poker_viewmodel.dart';

/// ポーカーのハンド表示
class HandList extends StatefulWidget {
  final PokerViewModel pokerViewModel;
  final List<PlayingCard> cardList;
  final bool isMyhand;

  const HandList({
    super.key,
    required this.pokerViewModel,
    required this.cardList,
    this.isMyhand = false,
  });

  @override
  State<HandList> createState() => _HandListState();
}

class _HandListState extends State<HandList> {
  PokerViewModel get pokerViewModel => widget.pokerViewModel;

  void _toggleCard(PlayingCard card) {
    setState(() {
      if (pokerViewModel.selectedMyCards.contains(card)) {
        pokerViewModel.selectedMyCards.remove(card);
      } else {
        pokerViewModel.selectedMyCards.add(card);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.cardList.length, (index) {
              final card = widget.cardList[index];
              final isSelected = pokerViewModel.selectedMyCards.contains(card);
              return widget.isMyhand
                  ? Transform.translate(
                      offset: Offset(0, isSelected ? -10 : 0),
                      child: GestureDetector(
                        onTap: () => _toggleCard(card),
                        child: Image.network(card.image, fit: BoxFit.cover),
                      ),
                    )
                  : Image.network(AppStrings.cardBackUrl, fit: BoxFit.cover);
            }),
          ),
        ),
      ),
    );
  }
}
