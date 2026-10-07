import 'package:flutter/material.dart';
import 'package:poka_fugou_app/constants/strings.dart';
import 'package:poka_fugou_app/view_models/poker_viewmodel.dart';
import 'package:poka_fugou_app/views/view_container/card_image.dart';

/// 中央のエリア（山札と、進行に応じたボタン）
class PokerActionArea extends StatelessWidget {
  final PokerViewModel pokerViewModel;

  /// 「大富豪へ」を押したとき
  final VoidCallback onGoDaifugo;

  const PokerActionArea({
    super.key,
    required this.pokerViewModel,
    required this.onGoDaifugo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const CardImage(url: AppStrings.cardBackUrl),
        const SizedBox(height: 5),
        _button(),
      ],
    );
  }

  Widget _button() {
    final vm = pokerViewModel;
    if (!vm.isExchanged) {
      // 判定中はボタンを隠す（高さだけ確保）
      if (vm.isJudging) return const SizedBox(height: 40);
      return ElevatedButton(
        onPressed: vm.exchangeCard,
        child: Text(
          vm.selectedMyCards.isEmpty
              ? AppStrings.fightAsIs
              : AppStrings.exchange,
        ),
      );
    }
    if (vm.isTieBreak && vm.myTieCard == null) {
      // サドンデス（1枚ずつ引く）
      return ElevatedButton(
        onPressed: vm.drawTieBreakCards,
        child: const Text(AppStrings.suddenDeath),
      );
    }
    if (vm.isTieBreak) {
      // サドンデスのカードを表にする
      return ElevatedButton(
        onPressed: vm.isTieCardsOpen ? null : vm.openTieBreakCards,
        child: const Text(AppStrings.openCards),
      );
    }
    return ElevatedButton(
      onPressed: onGoDaifugo,
      child: const Text(AppStrings.daifugo),
    );
  }
}
