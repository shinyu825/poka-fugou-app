import 'package:flutter_test/flutter_test.dart';
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
  });
}
