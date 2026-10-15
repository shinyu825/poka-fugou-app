import 'package:flutter/material.dart';
import 'package:poka_fugou_app/models/api/playing_card.dart';
import 'package:poka_fugou_app/models/daifugo/daifugo_rules.dart';

/// Q ボンバーの数字選択（電卓風。選択中は明るくなる）
class BomberSelector extends StatelessWidget {
  final List<String> selectedValues;
  final void Function(String value) onTap;

  const BomberSelector({
    super.key,
    required this.selectedValues,
    required this.onTap,
  });

  static const int _columns = 4;

  @override
  Widget build(BuildContext context) {
    const values = DaifugoRules.bomberValues;
    final colors = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int row = 0; row < values.length ~/ _columns; row++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final value in values.sublist(
                row * _columns,
                (row + 1) * _columns,
              ))
                _key(value, selectedValues.contains(value), colors),
            ],
          ),
      ],
    );
  }

  Widget _key(String value, bool isSelected, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: InkWell(
        onTap: () => onTap(value),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 60,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            // 未選択はくすんだ灰色、選択中は明るいオレンジ
            color: isSelected ? colors.primaryContainer : Colors.grey.shade400,
            borderRadius: BorderRadius.circular(6),
            border: isSelected ? Border.all(color: colors.primary) : null,
          ),
          child: Text(
            PlayingCard.displayOf(value),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isSelected ? colors.onPrimaryContainer : Colors.black45,
            ),
          ),
        ),
      ),
    );
  }
}
