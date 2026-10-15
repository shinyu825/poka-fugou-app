import 'package:flutter/material.dart';
import 'package:poka_fugou_app/constants/strings.dart';
import 'package:poka_fugou_app/models/daifugo/field_play.dart';
import 'package:poka_fugou_app/views/view_container/card_image.dart';
import 'package:poka_fugou_app/views/view_container/daifugo/bomber_selector.dart';
import 'package:poka_fugou_app/views/view_container/daifugo/field_cards.dart';

/// 中央のエリア（山札・残り枚数・場のカード・メッセージ・Q ボンバーの数字表）
class DaifugoCenterArea extends StatelessWidget {
  final int remaining;
  final List<FieldPlay> fieldPlays;
  final String message;

  /// Q ボンバーの選択中なら選択済みの数字（null なら表を出さない）
  final List<String>? bomberValues;
  final void Function(String value)? onTapBomberValue;

  const DaifugoCenterArea({
    super.key,
    required this.remaining,
    required this.fieldPlays,
    required this.message,
    this.bomberValues,
    this.onTapBomberValue,
  });

  @override
  Widget build(BuildContext context) {
    final values = bomberValues;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CardImage(url: AppStrings.cardBackUrl),
            const SizedBox(width: 10),
            SizedBox(
              height: 100,
              child: Center(child: Text(AppStrings.remaining(remaining))),
            ),
            const SizedBox(width: 10),
            FieldCards(plays: fieldPlays),
          ],
        ),
        const SizedBox(height: 8),
        if (values != null)
          BomberSelector(
            selectedValues: values,
            onTap: onTapBomberValue ?? (_) {},
          )
        else
          SizedBox(
            height: 40,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(message, textAlign: TextAlign.center),
              ),
            ),
          ),
      ],
    );
  }
}
