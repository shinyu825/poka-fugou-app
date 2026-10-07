import 'package:flutter/material.dart';
import 'package:poka_fugou_app/constants/strings.dart';
import 'package:poka_fugou_app/view_models/daifugo_viewmodel.dart';
import 'package:poka_fugou_app/view_models/main_viewmodel.dart';
import 'package:poka_fugou_app/view_models/poker_viewmodel.dart';
import 'package:poka_fugou_app/views/daifugo_screen.dart';
import 'package:poka_fugou_app/views/view_container/api_state_handler.dart';
import 'package:poka_fugou_app/views/view_container/dialog/confirm_dialog.dart';
import 'package:poka_fugou_app/views/view_container/dialog/poker_result_dialog.dart';
import 'package:poka_fugou_app/views/view_container/poker/poker_action_area.dart';
import 'package:poka_fugou_app/views/view_container/poker/poker_my_area.dart';
import 'package:poka_fugou_app/views/view_container/poker/poker_opponent_area.dart';
import 'package:provider/provider.dart';

/// ポーカー画面
class PokerScreen extends StatefulWidget {
  const PokerScreen({super.key});

  @override
  State<PokerScreen> createState() => _PokerScreenState();
}

class _PokerScreenState extends State<PokerScreen> {
  /// 表示済みの結果ダイアログ回数
  int _shownResultCount = 0;

  /// 戻る確認
  Future<void> _onBack() async {
    final isOk = await showConfirmDialog(
      context,
      AppStrings.backConfirmTitle,
      AppStrings.backConfirmMessage,
    );
    if (!isOk || !mounted) return;
    context.read<MainViewModel>().resetGame();
    Navigator.of(context).pop();
  }

  /// 大富豪画面へ
  void _goDaifugo() {
    final mainViewModel = context.read<MainViewModel>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => DaifugoViewModel(mainViewModel),
          child: const DaifugoScreen(),
        ),
      ),
    );
    context.read<PokerViewModel>().onGoDaifugo();
  }

  /// 結果ダイアログ（表示回数が増えたときだけ出す）
  void _showResultIfNeeded(PokerViewModel pokerViewModel, int count) {
    if (count <= _shownResultCount) return;
    _shownResultCount = count;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => PokerResultDialog(
          result: pokerViewModel.resultStr,
          playerHand: pokerViewModel.myHandStr,
          opponentHand: pokerViewModel.playerHandStr,
          point: AppStrings.pointDelta(pokerViewModel.pointDelta),
        ),
      ).then((_) => pokerViewModel.onResultDialogClosed());
    });
  }

  @override
  Widget build(BuildContext context) {
    final pokerViewModel = context.watch<PokerViewModel>();
    final hasCards =
        pokerViewModel.myCardList.isNotEmpty ||
        pokerViewModel.cardList1.isNotEmpty;

    // 結果表示までの演出待ちの間は、戻る操作を含めて何も受け付けない
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || pokerViewModel.isWaiting || pokerViewModel.isLoading) {
          return;
        }
        _onBack();
      },
      child: AbsorbPointer(
        absorbing: pokerViewModel.isWaiting,
        child: ApiStateHandler(
          viewModel: pokerViewModel,
          child: Scaffold(
            appBar: AppBar(title: const Text(AppStrings.pokerTitle)),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!hasCards)
                    _NoCards(onDraw: pokerViewModel.firstDrawCard)
                  else ...[
                    PokerOpponentArea(pokerViewModel: pokerViewModel),
                    const SizedBox(height: 20),
                    PokerActionArea(
                      pokerViewModel: pokerViewModel,
                      onGoDaifugo: _goDaifugo,
                    ),
                    const SizedBox(height: 20),
                    PokerMyArea(pokerViewModel: pokerViewModel),
                  ],
                  ValueListenableBuilder<int>(
                    valueListenable: pokerViewModel.resultCount,
                    builder: (context, count, _) {
                      _showResultIfNeeded(pokerViewModel, count);
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// カードが配られる前の表示
class _NoCards extends StatelessWidget {
  final VoidCallback onDraw;

  const _NoCards({required this.onDraw});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(
          height: 100,
          child: Center(child: Text(AppStrings.nocard)),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: onDraw,
          child: const Text(AppStrings.cardDraw),
        ),
      ],
    );
  }
}
