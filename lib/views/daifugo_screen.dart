import 'package:flutter/material.dart';
import 'package:poka_fugou_app/constants/strings.dart';
import 'package:poka_fugou_app/view_models/daifugo_viewmodel.dart';
import 'package:poka_fugou_app/view_models/main_viewmodel.dart';
import 'package:poka_fugou_app/views/view_container/daifugo_hand_list.dart';
import 'package:poka_fugou_app/views/view_container/dialog/confirm_dialog.dart';
import 'package:provider/provider.dart';

/// 大富豪画面
class DaifugoScreen extends StatefulWidget {
  final MainViewModel mainViewModel;
  const DaifugoScreen({super.key, required this.mainViewModel});

  @override
  State<DaifugoScreen> createState() => _DaifugoScreenState();
}

class _DaifugoScreenState extends State<DaifugoScreen> {
  late DaifugoViewModel daifugoViewModel;

  @override
  void initState() {
    super.initState();
    // daifugoViewModel = Provider.of<DaifugoViewModel>(context, listen: false);
    daifugoViewModel = DaifugoViewModel(widget.mainViewModel);
    // 画面描画後に通信開始
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      daifugoViewModel.daifugoDrawCard(context);
    });
  }

  @override
  void dispose() {
    // daifugoViewModel.clearAll();
    super.dispose();
  }

  /// 戻る確認（OKならスタート画面まで戻る）
  Future<void> _onBack() async {
    final isOk = await showConfirmDialog(
      context,
      AppStrings.backConfirmTitle,
      AppStrings.backConfirmMessage,
    );
    if (!isOk || !mounted) return;
    widget.mainViewModel.resetGame();
    Navigator.of(context).popUntil((route) => route.isFirst);
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
        appBar: AppBar(title: const Text(AppStrings.daifugoTitle)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChangeNotifierProvider<DaifugoViewModel>.value(
                value: daifugoViewModel,
                child: Consumer<DaifugoViewModel>(
                  builder: (context, daifugoViewModel, _) {
                    return Column(
                      children: [
                        // 相手1のカード(裏面)
                        DaifugoHandList(
                          daifugoViewModel: daifugoViewModel,
                          cardList: daifugoViewModel.cardList1,
                          isMyhand: false,
                        ),
                        const SizedBox(height: 20),
                        Column(
                          children: [
                            // 山札と残り枚数
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: 100,
                                  child: Image.network(
                                    AppStrings.cardBackUrl,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  AppStrings.remaining(
                                    daifugoViewModel.remaining,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            // カード出すorパスボタン
                            if (daifugoViewModel
                                .selectedMyCards
                                .isNotEmpty) ...[
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
                          daifugoViewModel: daifugoViewModel,
                          cardList: daifugoViewModel.myCardList,
                          isMyhand: true,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
