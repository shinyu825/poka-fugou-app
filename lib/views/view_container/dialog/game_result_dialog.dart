import 'package:flutter/material.dart';
import 'package:poka_fugou_app/constants/strings.dart';

/// 勝敗の結果ダイアログ（ポーカー・大富豪で共通）
class GameResultDialog extends StatelessWidget {
  final String result;

  /// 役や残り枚数などの説明行
  final List<String> details;
  final String point;

  const GameResultDialog({
    super.key,
    required this.result,
    required this.details,
    required this.point,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            result,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          for (final detail in details) ...[
            Text(detail, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 10),
          Text(
            point,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text(AppStrings.back),
          ),
        ],
      ),
    );
  }
}
