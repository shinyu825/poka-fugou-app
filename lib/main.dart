import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:poka_fugou_app/constants/difficulty.dart';
import 'package:poka_fugou_app/constants/strings.dart';
import 'package:poka_fugou_app/view_models/main_viewmodel.dart';
import 'package:poka_fugou_app/view_models/poker_viewmodel.dart';
import 'package:poka_fugou_app/views/poker_screen.dart';
import 'package:poka_fugou_app/views/view_container/api_state_handler.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 縦向き固定
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(
    ChangeNotifierProvider(
      create: (_) => MainViewModel()..loadDifficulty(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appTitle,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
      ),
      home: const MyHomePage(title: AppStrings.appTitle),
    );
  }
}

/// メイン画面（最初の画面）
class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  /// デッキを作ってポーカー画面へ
  Future<void> _startGame(BuildContext context) async {
    final mainViewModel = context.read<MainViewModel>();
    final isSuccess = await mainViewModel.createDeck();
    if (!isSuccess || !context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => PokerViewModel(mainViewModel),
          child: const PokerScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mainViewModel = context.watch<MainViewModel>();

    return ApiStateHandler(
      viewModel: mainViewModel,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(title),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 難易度選択
              SegmentedButton<Difficulty>(
                segments: [
                  for (final d in Difficulty.values)
                    ButtonSegment(value: d, label: Text(d.jpName)),
                ],
                selected: {mainViewModel.difficulty},
                onSelectionChanged: (selected) {
                  mainViewModel.setDifficulty(selected.first);
                },
              ),
              const SizedBox(height: 20),
              // 開始ボタン
              ElevatedButton(
                onPressed: () => _startGame(context),
                child: const Text(AppStrings.startGame),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
