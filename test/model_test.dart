import 'package:cashkittymeow/model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('money parsing', () {
    test('converts decimal strings to cents', () {
      expect(parseMoneyToCents('12'), 1200);
      expect(parseMoneyToCents('12.3'), 1230);
      expect(parseMoneyToCents('12.34'), 1234);
      expect(parseMoneyToCents('.99'), 99);
      expect(parseMoneyToCents('-5.25'), -525);
      expect(parseMoneyToCents('1,234.56'), 123456);
    });

    test('rejects ambiguous or over-precise money values', () {
      expect(parseMoneyToCents(''), isNull);
      expect(parseMoneyToCents('abc'), isNull);
      expect(parseMoneyToCents('12.345'), isNull);
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
      expect(account.transactions.single.formattedAmount, '-3.50');
    });
  });
}
