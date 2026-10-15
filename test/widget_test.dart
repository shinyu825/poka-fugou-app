import 'package:flutter_test/flutter_test.dart';
import 'package:poka_fugou_app/constants/rules.dart';
import 'package:poka_fugou_app/constants/strings.dart';
import 'package:poka_fugou_app/main.dart';
import 'package:poka_fugou_app/view_models/main_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('スタート画面が表示される', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => MainViewModel(),
        child: const MyApp(),
      ),
    );

    expect(find.text(AppStrings.appTitle), findsOneWidget);
    expect(find.text(AppStrings.startGame), findsOneWidget);
    expect(find.text(AppStrings.easy), findsOneWidget);
    expect(find.text(AppStrings.hard), findsOneWidget);
    expect(find.text(AppStrings.showRules), findsOneWidget);
  });

  testWidgets('ルール画面はタブで切り替えられる', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => MainViewModel(),
        child: const MyApp(),
      ),
    );
    await tester.tap(find.text(AppStrings.showRules));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.rulesTitle), findsOneWidget);
    expect(find.text(Rules.pokaFugou.first.title), findsOneWidget);

    await tester.tap(find.text(AppStrings.pokerTitle));
    await tester.pumpAndSettle();
    expect(find.text('ファイブカード'), findsOneWidget);

    await tester.tap(find.text(AppStrings.daifugoTitle));
    await tester.pumpAndSettle();
    expect(find.text(Rules.daifugo.first.title), findsOneWidget);
  });
}
