import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:prolink/l10n.dart';
import 'package:prolink/main.dart';

void main() {
  testWidgets('ProLink app boots', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppLocale(),
        child: const ProLinkApp(),
      ),
    );
    expect(find.text('ProLink'), findsOneWidget);
  });
}
