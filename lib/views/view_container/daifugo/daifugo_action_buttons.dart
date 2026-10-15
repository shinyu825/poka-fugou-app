import 'package:flutter/material.dart';

/// ハンドの下の左右ボタン（文言が null なら非表示。高さは常に確保する）
class DaifugoActionButtons extends StatelessWidget {
  final String? leftLabel;
  final String? rightLabel;
  final bool isRightEnabled;
  final VoidCallback onLeft;
  final VoidCallback onRight;

  const DaifugoActionButtons({
    super.key,
    required this.leftLabel,
    required this.rightLabel,
    required this.isRightEnabled,
    required this.onLeft,
    required this.onRight,
  });

  static const double _width = 120;
  static const double _height = 40;

  @override
  Widget build(BuildContext context) {
    final left = leftLabel;
    final right = rightLabel;
    return SizedBox(
      height: _height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: _width,
            child: left == null
                ? null
                : OutlinedButton(onPressed: onLeft, child: Text(left)),
          ),
          const SizedBox(width: 20),
          SizedBox(
            width: _width,
            child: right == null
                ? null
                : ElevatedButton(
                    onPressed: isRightEnabled ? onRight : null,
                    child: Text(right),
                  ),
          ),
        ],
      ),
    );
  }
}
