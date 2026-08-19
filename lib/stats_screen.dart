import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'model.dart';
import 'myprovider.dart';

class StatsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final accounts = context.watch<AccountProvider>().accounts;
    final stats = _Stats.fromAccounts(accounts);

    return Scaffold(
      appBar: AppBar(title: Text('Stats')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _SummaryGrid(stats: stats),
            SizedBox(height: 16),
            _SectionTitle('Accounts'),
            if (accounts.isEmpty)
              Text('No accounts yet.')
            else
              ...accounts.map((account) => _AccountStatRow(account: account)),
            SizedBox(height: 16),
            _SectionTitle('Spending By Category'),
            if (stats.categoryTotals.isEmpty)
              Text('No spending categories yet.')
            else
              ...stats.sortedCategoryTotals.map(
                (entry) => _BarStatRow(
                  label: entry.key.label,
                  value: entry.value,
                  maxValue: stats.maxCategoryTotal,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final _Stats stats;

  _SummaryGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 2.2,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        _SummaryTile(label: 'Cash', value: stats.cashTotalCents),
        _SummaryTile(label: 'Debt', value: stats.debtTotalCents),
        _SummaryTile(label: 'Net', value: stats.netWorthCents),
        _SummaryTile(label: 'Spending', value: stats.spendingTotalCents),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final int value;

  _SummaryTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(color: Colors.black54)),
          SizedBox(height: 4),
          Text(
            formatCents(value),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _AccountStatRow extends StatelessWidget {
  final Account account;

  _AccountStatRow({required this.account});

  @override
  Widget build(BuildContext context) {
    final availableCredit = account.formattedAvailableCredit;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(account.title),
      subtitle: Text(
        availableCredit == null
            ? account.accountType.label
            : '${account.accountType.label} - Available: $availableCredit',
      ),
      trailing: Text(
        account.formattedBalance,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _BarStatRow extends StatelessWidget {
  final String label;
  final int value;
  final int maxValue;

  _BarStatRow({
    required this.label,
    required this.value,
    required this.maxValue,
  });

  @override
  Widget build(BuildContext context) {
    final progress = maxValue == 0 ? 0.0 : value / maxValue;

    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label)),
              Text(formatCents(value)),
            ],
          ),
          SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.black12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _Stats {
  final int cashTotalCents;
  final int debtTotalCents;
  final int spendingTotalCents;
  final Map<TransactionCategory, int> categoryTotals;

  _Stats({
    required this.cashTotalCents,
    required this.debtTotalCents,
    required this.spendingTotalCents,
    required this.categoryTotals,
  });

  int get netWorthCents => cashTotalCents - debtTotalCents;

  List<MapEntry<TransactionCategory, int>> get sortedCategoryTotals {
    return categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }

  int get maxCategoryTotal {
    if (categoryTotals.isEmpty) {
      return 0;
    }
    return categoryTotals.values.reduce((a, b) => a > b ? a : b);
  }

  factory _Stats.fromAccounts(List<Account> accounts) {
    var cashTotalCents = 0;
    var debtTotalCents = 0;
    var spendingTotalCents = 0;
    final categoryTotals = <TransactionCategory, int>{};

    for (final account in accounts) {
      switch (account.accountType) {
        case AccountType.bankAccount:
          if (account.balanceCents >= 0) {
            cashTotalCents += account.balanceCents;
          } else {
            debtTotalCents += -account.balanceCents;
          }
          break;
        case AccountType.creditCard:
        case AccountType.loan:
          if (account.balanceCents >= 0) {
            debtTotalCents += account.balanceCents;
          } else {
            cashTotalCents += -account.balanceCents;
          }
          break;
      }

      for (final transaction in account.transactions) {
        if (!transaction.countsTowardSpendingStats) {
          continue;
        }
        spendingTotalCents += transaction.enteredAmountCents;
        categoryTotals.update(
          transaction.category,
          (total) => total + transaction.enteredAmountCents,
          ifAbsent: () => transaction.enteredAmountCents,
        );
      }
    }

    return _Stats(
      cashTotalCents: cashTotalCents,
      debtTotalCents: debtTotalCents,
      spendingTotalCents: spendingTotalCents,
      categoryTotals: categoryTotals,
    );
  }
}
