import 'package:flutter/material.dart';
import 'package:poka_fugou_app/constants/strings.dart';
import 'package:poka_fugou_app/view_models/daifugo_viewmodel.dart';
import 'package:poka_fugou_app/view_models/main_viewmodel.dart';
import 'package:poka_fugou_app/views/rules_screen.dart';
import 'package:poka_fugou_app/views/view_container/api_state_handler.dart';
import 'package:poka_fugou_app/views/view_container/daifugo/daifugo_action_buttons.dart';
import 'package:poka_fugou_app/views/view_container/daifugo/daifugo_center_area.dart';
import 'package:poka_fugou_app/views/view_container/daifugo_hand_list.dart';
import 'package:poka_fugou_app/views/view_container/dialog/confirm_dialog.dart';
import 'package:poka_fugou_app/views/view_container/dialog/error_dialog.dart';
import 'package:poka_fugou_app/views/view_container/dialog/final_result_dialog.dart';
import 'package:poka_fugou_app/views/view_container/dialog/game_result_dialog.dart';
import 'package:provider/provider.dart';

/// 大富豪画面
class DaifugoScreen extends StatefulWidget {
  const DaifugoScreen({super.key});

  @override
  State<DaifugoScreen> createState() => _DaifugoScreenState();
}

class _DaifugoScreenState extends State<DaifugoScreen> {
  /// 表示済みのダイアログ回数
  int _shownResultCount = 0;
  int _shownFinalCount = 0;
  bool _shownDeckExhausted = false;

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
    _toStart();
  }

  /// ゲームをリセットしてスタート画面へ
  void _toStart() {
    context.read<MainViewModel>().resetGame();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  /// 結果ダイアログ（表示回数が増えたときだけ出す）
  void _showResultIfNeeded(DaifugoViewModel vm, int count) {
    if (count <= _shownResultCount) return;
    _shownResultCount = count;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => GameResultDialog(
          result: vm.resultStr,
          details: vm.resultDetails,
          point: AppStrings.pointDelta(vm.pointDelta),
        ),
      ).then((_) => vm.onResultDialogClosed());
    });
  }

  /// 最終結果ダイアログ（閉じるとスタート画面へ）
  void _showFinalIfNeeded(DaifugoViewModel vm, int count) {
    if (count <= _shownFinalCount) return;
    _shownFinalCount = count;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => FinalResultDialog(
          myPokerPoint: vm.pokerMyPoint,
          myDaifugoPoint: vm.pointDelta,
          pokerPoint1: -vm.pokerMyPoint,
          daifugoPoint1: -vm.pointDelta,
          onToStart: () {
            Navigator.of(dialogContext).pop();
            _toStart();
          },
        ),
      );
    });
  }

  /// 山札切れダイアログ（閉じるとスタート画面へ）
  void _showDeckExhaustedIfNeeded(DaifugoViewModel vm) {
    if (!vm.isDeckExhausted || _shownDeckExhausted) return;
    _shownDeckExhausted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await showErrorDialog(
        context,
        AppStrings.deckExhaustedTitle,
        AppStrings.deckExhaustedMessage,
      );
      if (!mounted) return;
      _toStart();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DaifugoViewModel>();
    _showDeckExhaustedIfNeeded(vm);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || vm.isWaiting || vm.isLoading) return;
        _onBack();
      },
      child: AbsorbPointer(
        absorbing: vm.isWaiting,
        child: ApiStateHandler(
          viewModel: vm,
          child: Scaffold(
            appBar: AppBar(
              title: const Text(AppStrings.daifugoTitle),
              actions: [
                IconButton(
                  tooltip: AppStrings.rulesTitle,
                  icon: const Icon(Icons.help_outline),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RulesScreen()),
                  ),
                ),
              ],
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 相手
                  Text(AppStrings.opponentPoint(vm.point1)),
                  const SizedBox(height: 10),
                  DaifugoHandList(
                    cardList: vm.cardList1,
                    isOpen: vm.isOpenHands,
                  ),
                  const SizedBox(height: 16),
                  // 中央
                  DaifugoCenterArea(
                    remaining: vm.remaining,
                    fieldPlays: vm.fieldPlays,
                    message: vm.message,
                    bomberValues: vm.phase == DaifugoPhase.selectingBomber
                        ? vm.selectedValues
                        : null,
                    onTapBomberValue: vm.toggleSelectValue,
                  ),
                  const SizedBox(height: 16),
                  // 自分
                  DaifugoHandList(
                    cardList: vm.myCardList,
                    isMyhand: true,
                    selectedCards: vm.selectedMyCards,
                    selectableCards: vm.selectableCards,
                    onTapCard: vm.toggleSelectMyCard,
                  ),
                  const SizedBox(height: 10),
                  DaifugoActionButtons(
                    leftLabel: vm.leftButtonLabel,
                    rightLabel: vm.rightButtonLabel,
                    isRightEnabled: vm.isRightButtonEnabled,
                    onLeft: vm.onLeftButton,
                    onRight: vm.onRightButton,
                  ),
                  const SizedBox(height: 6),
                  Text(AppStrings.myPoint(vm.myPoint)),
                  ValueListenableBuilder<int>(
                    valueListenable: vm.resultCount,
                    builder: (context, count, _) {
                      _showResultIfNeeded(vm, count);
                      return const SizedBox.shrink();
                    },
                  ),
                  ValueListenableBuilder<int>(
                    valueListenable: vm.finalResultCount,
                    builder: (context, count, _) {
                      _showFinalIfNeeded(vm, count);
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
