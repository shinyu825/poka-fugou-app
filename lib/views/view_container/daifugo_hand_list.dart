import 'package:flutter/material.dart';
import 'package:poka_fugou_app/constants/strings.dart';
import 'package:poka_fugou_app/models/api/playing_card.dart';
import 'package:poka_fugou_app/view_models/daifugo_viewmodel.dart';

/// 大富豪のハンド
class DaifugoHandList extends StatefulWidget {
  final DaifugoViewModel daifugoViewModel;
  final List<PlayingCard> cardList;
  final bool isMyhand;

  const DaifugoHandList({
    super.key,
    required this.daifugoViewModel,
    required this.cardList,
    this.isMyhand = false,
  });

  @override
  State<DaifugoHandList> createState() => _DaifugoHandListState();
}

class _DaifugoHandListState extends State<DaifugoHandList> {
  DaifugoViewModel get daifugoViewModel => widget.daifugoViewModel;

  void _toggleCard(PlayingCard card) {
    setState(() {
      if (daifugoViewModel.selectedMyCards.contains(card)) {
        daifugoViewModel.selectedMyCards.remove(card);
      } else {
        daifugoViewModel.selectedMyCards.add(card);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const cardHeight = 100.0;
    const cardWidth = 72.0;
    const overlapOffset = 30.0; // ← カードの重なり具合（数値が大きいほど重なる）
    final cardCount = widget.cardList.length;
    final totalWidth = cardCount == 0
        ? 0.0
        : cardWidth + overlapOffset * (cardCount - 1);

    return SizedBox(
      height: cardHeight,
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: totalWidth,
            height: cardHeight,
            child: Stack(
              children: List.generate(cardCount, (index) {
                final card = widget.cardList[index];
                final isSelected = daifugoViewModel.selectedMyCards.contains(
                  card,
                );
                final image = Image.network(
                  widget.isMyhand ? card.image : AppStrings.cardBackUrl,
                  width: cardWidth,
                  height: cardHeight,
                  fit: BoxFit.cover,
                );

                return Positioned(
                  left: index * overlapOffset,
                  child: widget.isMyhand
                      ? Transform.translate(
                          offset: Offset(0, isSelected ? -10 : 0),
                          child: GestureDetector(
                            onTap: () => _toggleCard(card),
                            child: image,
                          ),
                        )
                      : image,
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
