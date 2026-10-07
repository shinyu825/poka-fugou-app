import 'package:flutter/material.dart';
import 'package:poka_fugou_app/constants/strings.dart';
import 'package:poka_fugou_app/view_models/daifugo_viewmodel.dart';
import 'package:poka_fugou_app/view_models/main_viewmodel.dart';
import 'package:poka_fugou_app/views/view_container/api_state_handler.dart';
import 'package:poka_fugou_app/views/view_container/card_image.dart';
import 'package:poka_fugou_app/views/view_container/daifugo_hand_list.dart';
import 'package:poka_fugou_app/views/view_container/dialog/confirm_dialog.dart';
import 'package:provider/provider.dart';

/// 大富豪画面
class DaifugoScreen extends StatefulWidget {
  const DaifugoScreen({super.key});

  @override
  State<DaifugoScreen> createState() => _DaifugoScreenState();
}

class _DaifugoScreenState extends State<DaifugoScreen> {
  @override
  void initState() {
    super.initState();
    // 画面描画後に通信開始
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DaifugoViewModel>().daifugoDrawCard();
    });
  }

  /// 戻る確認（OKならスタート画面まで戻る）
  Future<void> _onBack() async {
    final isOk = await showConfirmDialog(
      context,
      AppStrings.backConfirmTitle,
      AppStrings.backConfirmMessage,
    );
    if (!isOk || !mounted) return;
    context.read<MainViewModel>().resetGame();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final daifugoViewModel = context.watch<DaifugoViewModel>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || daifugoViewModel.isLoading) return;
        _onBack();
      },
      child: ApiStateHandler(
        viewModel: daifugoViewModel,
        child: Scaffold(
          appBar: AppBar(title: const Text(AppStrings.daifugoTitle)),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 相手1の現在のポイント
                Text(AppStrings.opponentPoint(daifugoViewModel.point1)),
                const SizedBox(height: 10),
                // 相手1のカード(裏面)
                DaifugoHandList(cardList: daifugoViewModel.cardList1),
                const SizedBox(height: 20),
                Column(
                  children: [
                    // 山札と残り枚数
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CardImage(url: AppStrings.cardBackUrl),
                        const SizedBox(width: 10),
                        Text(AppStrings.remaining(daifugoViewModel.remaining)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    // カード出すorパスボタン
                    if (daifugoViewModel.selectedMyCards.isNotEmpty) ...[
                      ElevatedButton(
                        onPressed: () {
                          // カード出す
                        },
                        child: const Text(AppStrings.put),
                      ),
                    ] else ...[
                      ElevatedButton(
                        onPressed: () {
                          // パス
                        },
                        child: const Text(AppStrings.pass),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),
                // 自分のカード
                DaifugoHandList(
                  cardList: daifugoViewModel.myCardList,
                  isMyhand: true,
                  selectedCards: daifugoViewModel.selectedMyCards,
                  onTapCard: daifugoViewModel.toggleSelectMyCard,
                ),
                const SizedBox(height: 10),
                // 現在のポイント
                Text(AppStrings.myPoint(daifugoViewModel.myPoint)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
