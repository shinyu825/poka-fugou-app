import 'package:flutter/material.dart';
import 'package:poka_fugou_app/constants/strings.dart';

/// ポーカー結果表示ダイアログ
class PokerResultDialog extends StatelessWidget {
  final String result;
  final String playerHand;
  final String opponentHand;

  const PokerResultDialog({
    super.key,
    required this.result,
    required this.playerHand,
    required this.opponentHand,
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
          Text(
            '${AppStrings.myHand}$playerHand',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 10),
          Text(
            '${AppStrings.player1Hand}$opponentHand',
            style: const TextStyle(fontSize: 18),
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
