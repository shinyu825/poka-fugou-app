import 'package:flutter/material.dart';
import 'package:poka_fugou_app/constants/strings.dart';
import 'package:poka_fugou_app/view_models/daifugo_viewmodel.dart';
import 'package:poka_fugou_app/view_models/main_viewmodel.dart';
import 'package:poka_fugou_app/view_models/poker_viewmodel.dart';
import 'package:poka_fugou_app/views/daifugo_screen.dart';
import 'package:poka_fugou_app/views/view_container/dialog/confirm_dialog.dart';
import 'package:poka_fugou_app/views/view_container/dialog/poker_result_dialog.dart';
import 'package:poka_fugou_app/views/view_container/hand_list.dart';
import 'package:provider/provider.dart';

/// ポーカー画面
class PokerScreen extends StatefulWidget {
  final MainViewModel mainViewModel;
  const PokerScreen({super.key, required this.mainViewModel});

  @override
  State<PokerScreen> createState() => _PokerScreenState();
}

class _PokerScreenState extends State<PokerScreen> {
  late PokerViewModel pokerViewModel;

  @override
  void initState() {
    super.initState();
    pokerViewModel = PokerViewModel(widget.mainViewModel);
  }

  @override
  void dispose() {
    // pokerViewModel.clearAll();
    super.dispose();
  }

  /// 戻る確認
  Future<void> _onBack() async {
    final isOk = await showConfirmDialog(
      context,
      AppStrings.backConfirmTitle,
      AppStrings.backConfirmMessage,
    );
    if (!isOk || !mounted) return;
    widget.mainViewModel.resetGame();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _onBack();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text(AppStrings.pokerTitle)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChangeNotifierProvider<PokerViewModel>.value(
                value: pokerViewModel,
                child: Consumer<PokerViewModel>(
                  builder: (context, pokerViewModel, _) {
                    if (pokerViewModel.myCardList.isEmpty &&
                        pokerViewModel.cardList1.isEmpty) {
                      // カードがない場合
                      return Column(
                        children: [
                          const SizedBox(
                            height: 100,
                            child: Center(child: Text(AppStrings.nocard)),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              pokerViewModel.firstDrawCard(context);
                            },
                            child: const Text(AppStrings.cardDraw),
                          ),
                        ],
                      );
                    } else {
                      // カードがある場合
                      return Column(
                        children: [
                          // 相手1のカード
                          if (pokerViewModel.isOpenHands.value) ...[
                            SizedBox(
                              height: 100,
                              child: Center(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      pokerViewModel.cardList1.length,
                                      (index) {
                                        return Image.network(
                                          pokerViewModel.cardList1[index].image,
                                          fit: BoxFit.cover,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ] else ...[
                            // 相手1のカード(裏面)
                            HandList(
                              pokerViewModel: pokerViewModel,
                              cardList: pokerViewModel.cardList1,
                              isMyhand: false,
                            ),
                          ],
                          const SizedBox(height: 20),
                          Column(
                            children: [
                              // 山札
                              SizedBox(
                                height: 100,
                                child: Image.network(
                                  AppStrings.cardBackUrl,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 5),
                              // カード交換ボタン
                              if (!pokerViewModel.isExchanged) ...[
                                ElevatedButton(
                                  onPressed: () {
                                    // カード交換
                                    pokerViewModel.exchangeCard(context);
                                  },
                                  child: const Text(AppStrings.exchange),
                                ),
                              ] else ...[
                                ElevatedButton(
                                  onPressed: () {
                                    // 大富豪へ
                                    if (!mounted) return;
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChangeNotifierProvider(
                                          create: (_) => DaifugoViewModel(
                                            widget.mainViewModel,
                                          ),
                                          child: DaifugoScreen(
                                            mainViewModel: widget.mainViewModel,
                                          ),
                                        ),
                                      ),
                                    );
                                    pokerViewModel.isOpenHands.value = false;
                                  },
                                  child: const Text(AppStrings.daifugo),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 20),
                          // 自分のカード
                          HandList(
                            pokerViewModel: pokerViewModel,
                            cardList: pokerViewModel.myCardList,
                            isMyhand: true,
                          ),
                        ],
                      );
                    }
                  },
                ),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: pokerViewModel.isOpenHands,
                builder: (context, isShow, _) {
                  if (isShow) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => PokerResultDialog(
                          result: pokerViewModel.resultStr,
                          playerHand: pokerViewModel.myHandStr,
                          opponentHand: pokerViewModel.playerHandStr,
                        ),
                      ).then((_) {
                        pokerViewModel.isExchanged = true;
                        pokerViewModel.updateViewModel();
                      });
                    });
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
