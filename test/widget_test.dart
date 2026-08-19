import 'package:cashcheetah/main.dart';
import 'package:cashcheetah/model.dart';
import 'package:cashcheetah/myprovider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('home screen asks new users to add an account',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final provider = AccountProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(home: HomeScreen()),
      ),
    );

    expect(find.text('CashCheetah'), findsOneWidget);
    expect(find.text('No accounts available.\nPlease add an account.'),
        findsOneWidget);
  });

  testWidgets('invalid transaction amount shows validation message',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final provider = AccountProvider();
    provider.addAccount('Checking', AccountType.bankAccount, 0);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(home: HomeScreen()),
      ),
    );

    await tester.tap(find.byIcon(Icons.add_card));
    await tester.pumpAndSettle();
    final formFields = find.byType(TextFormField);
    await tester.enterText(formFields.at(0), 'Coffee');
    await tester.enterText(formFields.at(1), 'nope');
    await tester.tap(find.text('Save Withdrawal'));
    await tester.pump();

    expect(find.text('Please enter a valid amount'), findsOneWidget);
  });
}
