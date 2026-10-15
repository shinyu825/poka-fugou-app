import 'package:flutter/material.dart';
import 'package:poka_fugou_app/constants/strings.dart';

/// 最終結果（ポーカー・大富豪・合計）のダイアログ
class FinalResultDialog extends StatelessWidget {
  final int myPokerPoint;
  final int myDaifugoPoint;
  final int pokerPoint1;
  final int daifugoPoint1;

  /// 「スタート画面へ」を押したとき
  final VoidCallback onToStart;

  const FinalResultDialog({
    super.key,
    required this.myPokerPoint,
    required this.myDaifugoPoint,
    required this.pokerPoint1,
    required this.daifugoPoint1,
    required this.onToStart,
  });

  @override
  Widget build(BuildContext context) {
    final myTotal = myPokerPoint + myDaifugoPoint;
    final total1 = pokerPoint1 + daifugoPoint1;
    final String verdict;
    if (myTotal > total1) {
      verdict = AppStrings.finalWin;
    } else if (myTotal < total1) {
      verdict = AppStrings.finalLose;
    } else {
      verdict = AppStrings.finalDraw;
    }
    const bold = TextStyle(fontWeight: FontWeight.bold);

    return AlertDialog(
      title: const Text(AppStrings.finalResultTitle, textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            verdict,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Table(
            columnWidths: const {0: FixedColumnWidth(80)},
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              _row('', AppStrings.you, AppStrings.opponent, style: bold),
              _row(
                AppStrings.pokerTitle,
                _pt(myPokerPoint),
                _pt(pokerPoint1),
              ),
              _row(
                AppStrings.daifugoTitle,
                _pt(myDaifugoPoint),
                _pt(daifugoPoint1),
              ),
              _row(AppStrings.total, _pt(myTotal), _pt(total1), style: bold),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onToStart,
            child: const Text(AppStrings.toStart),
          ),
        ],
      ),
    );
  }

  static String _pt(int point) => '${point}pt';

  TableRow _row(String label, String mine, String theirs, {TextStyle? style}) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(label, style: style),
        ),
        Text(mine, textAlign: TextAlign.center, style: style),
        Text(theirs, textAlign: TextAlign.center, style: style),
      ],
    );
  }
}
