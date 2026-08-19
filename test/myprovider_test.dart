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

  test('tutorial starts unseen and can be completed', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = AccountProvider();

    await provider.loadData();
    expect(provider.hasSeenTutorial, isFalse);

    await provider.completeTutorial();
    expect(provider.hasSeenTutorial, isTrue);
  });

  test('bank account actions apply balance changes internally', () {
    final provider = AccountProvider();
    provider.addAccount('Checking', AccountType.bankAccount, 0);

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

  test('reorderAccount keeps the selected account selected', () {
    final provider = AccountProvider();
    provider.addAccount('Checking', AccountType.bankAccount, 0);
    provider.addAccount('Savings', AccountType.bankAccount, 0);
    provider.addAccount('Card', AccountType.creditCard, 0);
    provider.setCurrentAccount(1);

    provider.reorderAccount(1, 3);

    expect(provider.accounts.map((account) => account.title), [
      'Checking',
      'Card',
      'Savings',
    ]);
    expect(provider.currentAccount!.title, 'Savings');
    expect(provider.currentAccountIndex, 2);
  });

  test('updateTransactionForAccount can move a transaction between accounts',
      () {
    final provider = AccountProvider();
    provider.addAccount('Checking', AccountType.bankAccount, 10000);
    provider.addAccount('Savings', AccountType.bankAccount, 5000);
    provider.addTransactionToAccount(
      0,
      'Groceries',
      TransactionAction.withdrawalPurchase,
      2500,
      TransactionCategory.food,
      DateTime.utc(2026, 1, 1),
    );

    provider.updateTransactionForAccount(
      oldAccountIndex: 0,
      newAccountIndex: 1,
      transactionIndex: 0,
      newDescription: 'Moved groceries',
      newAction: TransactionAction.withdrawalPurchase,
      newEnteredAmountCents: 2000,
      newCategory: TransactionCategory.food,
      newDate: DateTime.utc(2026, 1, 2),
    );

    expect(provider.accounts[0].balanceCents, 10000);
    expect(provider.accounts[0].transactions, isEmpty);
    expect(provider.accounts[1].balanceCents, 3000);
    expect(provider.accounts[1].transactions.single.description,
        'Moved groceries');
  });
}
