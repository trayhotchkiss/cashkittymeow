import 'package:cashcheetah/model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('money parsing', () {
    test('converts decimal strings to cents', () {
      expect(parseMoneyToCents('12'), 1200);
      expect(parseMoneyToCents('12.3'), 1230);
      expect(parseMoneyToCents('12.34'), 1234);
      expect(parseMoneyToCents('.99'), 99);
      expect(parseMoneyToCents('-5.25'), -525);
    });

    test('rejects ambiguous or over-precise money values', () {
      expect(parseMoneyToCents(''), isNull);
      expect(parseMoneyToCents('abc'), isNull);
      expect(parseMoneyToCents('12.345'), isNull);
      expect(parseMoneyToCents('1,234.56'), isNull);
      expect(parseMoneyToCents(',22'), isNull);
      expect(parseMoneyToCents('12,34'), isNull);
      expect(parseMoneyToCents('12. 34'), isNull);
    });

    test('formats cents with two decimal places', () {
      expect(formatCents(0), '0.00');
      expect(formatCents(5), '0.05');
      expect(formatCents(1234), '12.34');
      expect(formatCents(-525), '-5.25');
    });
  });

  group('model serialization', () {
    test('writes cents-based account and transaction JSON', () {
      final account = Account(
        title: 'Checking',
        balanceCents: 12345,
        transactions: [
          Transaction(
            date: DateTime.utc(2026, 1, 2),
            description: 'Deposit',
            amountCents: 12345,
          ),
        ],
      );

      expect(account.toJson()['balanceCents'], 12345);
      expect(account.transactions.single.toJson()['amountCents'], 12345);
    });

    test('loads legacy decimal account and transaction JSON', () {
      final account = Account.fromJson({
        'title': 'Legacy',
        'balance': 10.25,
        'transactions': [
          {
            'date': '2026-01-02T00:00:00.000Z',
            'description': 'Coffee',
            'amount': -3.5,
          },
        ],
      });

      expect(account.balanceCents, 1025);
      expect(account.transactions.single.amountCents, -350);
      expect(account.formattedBalance, '10.25');
      expect(account.transactions.single.formattedAmount, '3.50');
      expect(
        account.transactions.single.action,
        TransactionAction.withdrawalPurchase,
      );
    });
  });

  group('backup serialization', () {
    test('creates and reads a versioned backup file shape', () {
      final account = Account(
        title: 'Savings',
        balanceCents: 2500,
        transactions: [
          Transaction(
            date: DateTime.utc(2026, 2, 3),
            description: 'Interest',
            amountCents: 125,
          ),
        ],
      );

      final backupJson = backupJsonFromAccounts([account]);
      final restoredAccounts = accountsFromBackupJson(backupJson);

      expect(backupJson['format'], 'cashcheetah.backup');
      expect(backupJson['version'], 1);
      expect(restoredAccounts, hasLength(1));
      expect(restoredAccounts.single.title, 'Savings');
      expect(restoredAccounts.single.accountType, AccountType.bankAccount);
      expect(restoredAccounts.single.balanceCents, 2500);
      expect(restoredAccounts.single.transactions.single.amountCents, 125);
    });

    test('rejects non CashCheetah backup data', () {
      expect(
        () => accountsFromBackupJson({
          'format': 'something-else',
          'version': 1,
          'accounts': [],
        }),
        throwsFormatException,
      );
    });
  });

  group('stored data recovery', () {
    test('keeps valid saved accounts and skips malformed records', () {
      final accounts = recoverAccountsFromStoredJsonList([
        '{"title":"Savings","balanceCents":2500,"transactions":[]}',
        '',
        '{"title":',
      ]);

      expect(accounts, hasLength(1));
      expect(accounts.single.title, 'Savings');
      expect(accounts.single.balanceCents, 2500);
    });

    test('uses fallbacks for partial account and transaction corruption', () {
      final account = Account.fromJson({
        'title': '',
        'balanceCents': 1200,
        'transactions': [
          {
            'date': 'not-a-date',
            'description': '',
            'amountCents': -499,
          },
          'not-a-transaction',
        ],
      });

      expect(account.title, 'Untitled Account');
      expect(account.transactions, hasLength(1));
      expect(account.transactions.single.description, 'Untitled Transaction');
      expect(account.transactions.single.amountCents, -499);
      expect(account.transactions.single.category, TransactionCategory.other);
    });

    test('treats malformed transaction lists as empty', () {
      final account = Account.fromJson({
        'title': 'Checking',
        'balanceCents': 1200,
        'transactions': 'not-a-list',
      });

      expect(account.transactions, isEmpty);
    });
  });

  group('account and transaction metadata', () {
    test('bank account transaction actions prefer withdrawals first', () {
      expect(
        AccountType.bankAccount.transactionActions,
        [
          TransactionAction.withdrawalPurchase,
          TransactionAction.deposit,
        ],
      );
    });

    test('food category is labeled as groceries and dining out is separate', () {
      expect(TransactionCategory.food.label, 'Groceries');
      expect(TransactionCategory.food.storageKey, 'food');
      expect(TransactionCategory.diningOut.label, 'Dining Out');
      expect(
        transactionCategoryFromJson('diningOut'),
        TransactionCategory.diningOut,
      );
    });

    test('reads account types, actions, and categories from JSON', () {
      final account = Account.fromJson({
        'title': 'Card',
        'accountType': 'creditCard',
        'balanceCents': 2500,
        'creditLimitCents': 10000,
        'transactions': [
          {
            'date': '2026-01-02T00:00:00.000Z',
            'description': 'Groceries',
            'action': 'charge',
            'category': 'food',
            'amountCents': 1999,
          },
        ],
      });

      expect(account.accountType, AccountType.creditCard);
      expect(account.creditLimitCents, 10000);
      expect(account.formattedAvailableCredit, '75.00');
      expect(account.toJson()['creditLimitCents'], 10000);
      expect(account.transactions.single.action, TransactionAction.charge);
      expect(account.transactions.single.category, TransactionCategory.food);
      expect(account.transactions.single.countsTowardSpendingStats, isTrue);
    });

    test('applies transaction actions without negative user input', () {
      expect(balanceEffectCents(TransactionAction.deposit, 1000), 1000);
      expect(
        balanceEffectCents(TransactionAction.withdrawalPurchase, 1000),
        -1000,
      );
      expect(balanceEffectCents(TransactionAction.payment, 1000), -1000);
      expect(balanceEffectCents(TransactionAction.charge, 1000), 1000);
    });
  });
}
