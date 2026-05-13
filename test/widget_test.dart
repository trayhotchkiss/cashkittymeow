import 'package:cashcheetah/main.dart';
import 'package:cashcheetah/myprovider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('home screen shows default account balance',
      (WidgetTester tester) async {
    final provider = AccountProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(home: HomeScreen()),
      ),
    );

    expect(find.text('CashCheetah'), findsOneWidget);
    expect(find.text('Total Balance: 0.00'), findsOneWidget);
  });

  testWidgets('invalid transaction amount shows validation message',
      (WidgetTester tester) async {
    final provider = AccountProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(home: HomeScreen()),
      ),
    );

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    final formFields = find.byType(TextFormField);
    await tester.enterText(formFields.at(0), 'Coffee');
    await tester.enterText(formFields.at(1), 'nope');
    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(find.text('Please enter a valid amount'), findsOneWidget);
  });
}
