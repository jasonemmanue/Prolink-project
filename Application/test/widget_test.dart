import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prolink/api/session.dart';
import 'package:prolink/l10n.dart';
import 'package:prolink/main.dart';

void main() {
  testWidgets('ProLink app boots', (WidgetTester tester) async {
    // Aucune session mémorisée → onboarding.
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppLocale()),
          ChangeNotifierProvider.value(value: Session.instance),
        ],
        child: const ProLinkApp(),
      ),
    );
    expect(find.text('ProLink'), findsOneWidget);

    // Laisse expirer le timer du splash (1,4 s) : navigation vers l'onboarding.
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Passer'), findsOneWidget);
  });
}
