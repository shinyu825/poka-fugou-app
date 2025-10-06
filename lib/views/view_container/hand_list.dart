import 'package:flutter/material.dart';
import 'package:poka_fugou_app/constants/strings.dart';
import 'package:poka_fugou_app/models/api/playing_card.dart';
import 'package:poka_fugou_app/view_models/main_viewmodel.dart';

class HandList extends StatefulWidget {
  final MainViewModel mainViewModel;
  final List<PlayingCard> cardList;
  final bool isMyhand;

  const HandList({
    super.key,
    required this.mainViewModel,
    required this.cardList,
    this.isMyhand = false,
  });

  @override
  State<HandList> createState() => _HandListState();
}

class _HandListState extends State<HandList> {
  MainViewModel get mainViewModel => widget.mainViewModel;

  void _toggleCard(PlayingCard card) {
    setState(() {
      if (mainViewModel.selectedMyCards.contains(card)) {
        mainViewModel.selectedMyCards.remove(card);
      } else {
        mainViewModel.selectedMyCards.add(card);
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
              final isSelected = mainViewModel.selectedMyCards.contains(
                widget.cardList[index],
              );
              return widget.isMyhand
                  ? Transform.translate(
                      offset: Offset(0, isSelected ? -10 : 0),
                      child: GestureDetector(
                        onTap: () => _toggleCard(widget.cardList[index]),
                        child: Image.network(
                          widget.cardList[index].image,
                          fit: BoxFit.cover,
                        ),
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
