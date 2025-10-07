import 'package:flutter/material.dart';
import 'package:poka_fugou_app/constants/strings.dart';
import 'package:poka_fugou_app/view_models/main_viewmodel.dart';
import 'package:poka_fugou_app/views/view_container/dialog/poker_result_dialog.dart';
import 'package:poka_fugou_app/views/view_container/hand_list.dart';
import 'package:provider/provider.dart';

class PokerScreen extends StatefulWidget {
  final MainViewModel mainViewModel;

  const PokerScreen({super.key, required this.mainViewModel});

  @override
  State<PokerScreen> createState() => _PokerScreenState();
}

class _PokerScreenState extends State<PokerScreen> {
  MainViewModel get mainViewModel => widget.mainViewModel;

  @override
  void dispose() {
    mainViewModel.clearAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.pokerTitle)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ChangeNotifierProvider<MainViewModel>.value(
              value: mainViewModel,
              child: Consumer<MainViewModel>(
                builder: (context, mainViewModel, _) {
                  if (mainViewModel.myCardList.isEmpty &&
                      mainViewModel.cardList1.isEmpty) {
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
                            mainViewModel.firstDrawCard(context);
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
                        if (mainViewModel.isOpenHands.value) ...[
                          SizedBox(
                            height: 100,
                            child: Center(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    mainViewModel.cardList1.length,
                                    (index) {
                                      return Image.network(
                                        mainViewModel.cardList1[index].image,
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
                            mainViewModel: mainViewModel,
                            cardList: mainViewModel.cardList1,
                            isMyhand: false,
                          ),
                          // SizedBox(
                          //   height: 100,
                          //   child: Center(
                          //     child: SingleChildScrollView(
                          //       scrollDirection: Axis.horizontal,
                          //       child: Row(
                          //         mainAxisAlignment: MainAxisAlignment.center,
                          //         children: List.generate(
                          //           mainViewModel.cardList1.length,
                          //           (index) {
                          //             return Image.network(
                          //               mainViewModel.cardList1[index].image,
                          //               fit: BoxFit.cover,
                          //             );
                          //           },
                          //         ),
                          //       ),
                          //     ),
                          //   ),
                          // ),
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
                            if (!mainViewModel.isExchanged) ...[
                              ElevatedButton(
                                onPressed: () {
                                  // カード交換
                                  mainViewModel.exchangeCard(context);
                                },
                                child: const Text(AppStrings.exchange),
                              ),
                            ] else ...[
                              ElevatedButton(
                                onPressed: () {
                                  // 大富豪へ
                                  mainViewModel.isOpenHands.value = false;
                                  debugPrint('大富豪へ');
                                },
                                child: const Text(AppStrings.daifugo),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 20),
                        // 自分のカード
                        HandList(
                          mainViewModel: mainViewModel,
                          cardList: mainViewModel.myCardList,
                          isMyhand: true,
                        ),
                      ],
                    );
                  }
                },
              ),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: mainViewModel.isOpenHands,
              builder: (context, isShow, _) {
                if (isShow) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => PokerResultDialog(
                        result: mainViewModel.resultStr,
                        playerHand: mainViewModel.myHandStr,
                        opponentHand: mainViewModel.playerHandStr,
                      ),
                    ).then((_) {
                      mainViewModel.isExchanged = true;
                      mainViewModel.updateViewModel();
                    });
                  });
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}
