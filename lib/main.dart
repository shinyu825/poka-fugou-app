import 'package:flutter/material.dart';
import 'package:poka_fugou_app/constants/strings.dart';
import 'package:poka_fugou_app/view_models/main_viewmodel.dart';
import 'package:poka_fugou_app/view_models/poker_viewmodel.dart';
import 'package:poka_fugou_app/views/poker_screen.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => MainViewModel(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'poka_fugou_app',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
      ),
      home: const MyHomePage(title: AppStrings.appTitle),
    );
  }
}

/// メイン画面（最初の画面）
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with RouteAware {
  late MainViewModel mainViewModel;

  @override
  void initState() {
    super.initState();
    mainViewModel = Provider.of<MainViewModel>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    // 画面遷移処理
    if (mainViewModel.isGoPokerScreen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            // builder: (_) => PokerScreen(mainViewModel: mainViewModel),
            builder: (_) => ChangeNotifierProvider(
              create: (_) => PokerViewModel(mainViewModel),
              child: PokerScreen(mainViewModel: mainViewModel),
            ),
          ),
        );
        mainViewModel.isGoPokerScreen = false;
      });
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        // 開始ボタン
        child: ElevatedButton(
          onPressed: () async {
            // デッキ生成
            await mainViewModel.createDeck(context);
            setState(() {});
          },
          child: const Text(AppStrings.startGame),
        ),
      ),
    );
  }
}
