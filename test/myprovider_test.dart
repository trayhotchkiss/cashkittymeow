import 'dart:convert';

import 'package:cashcheetah/model.dart';
import 'package:cashcheetah/myprovider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('loadData skips corrupt saved account records and shows a notice',
      () async {
    final validAccount = jsonEncode(
      Account(title: 'Checking', balanceCents: 1200).toJson(),
    );
    SharedPreferences.setMockInitialValues({
      'accounts': [validAccount, '{bad json'],
    });
    final provider = AccountProvider();

    await provider.loadData();

    expect(provider.accounts, hasLength(1));
    expect(provider.accounts.single.title, 'Checking');
    expect(provider.dataNotice, isNotNull);
  });

  test('loadData allows an intentionally empty saved account list', () async {
    SharedPreferences.setMockInitialValues({'accounts': <String>[]});
    final provider = AccountProvider();

    await provider.loadData();

    expect(provider.accounts, isEmpty);
    expect(provider.currentAccount, isNull);
    expect(provider.dataNotice, isNull);
  });

  test('bank account actions apply balance changes internally', () {
    final provider = AccountProvider();

    provider.addTransaction(
      'Paycheck',
      TransactionAction.deposit,
      10000,
      TransactionCategory.paycheck,
      DateTime.utc(2026, 1, 1),
    );
    provider.addTransaction(
      'Groceries',
      TransactionAction.withdrawalPurchase,
      2500,
      TransactionCategory.food,
      DateTime.utc(2026, 1, 2),
    );

    expect(provider.currentAccount!.balanceCents, 7500);
    expect(provider.currentAccount!.transactions.last.amountCents, -2500);
  });

  test('credit card actions apply owed-balance changes internally', () {
    final provider = AccountProvider();
    provider.addAccount('Card', AccountType.creditCard, 0);

    provider.addTransaction(
      'Dinner',
      TransactionAction.charge,
      3000,
      TransactionCategory.food,
      DateTime.utc(2026, 1, 1),
    );
    provider.addTransaction(
      'Card payment',
      TransactionAction.payment,
      1000,
      TransactionCategory.other,
      DateTime.utc(2026, 1, 2),
    );

    expect(provider.currentAccount!.balanceCents, 2000);
    expect(provider.currentAccount!.transactions.last.amountCents, -1000);
  });
}
