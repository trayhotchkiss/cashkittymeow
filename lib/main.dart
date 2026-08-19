import 'package:flutter/material.dart';
import 'myprovider.dart';
import 'package:provider/provider.dart';
import 'account_dialog.dart';
import 'manage_accounts_screen.dart';
import 'model.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';
import 'transaction_form.dart';
import 'tutorial_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) {
        final provider = AccountProvider();
        provider.loadData();
        return provider;
      },
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: TutorialGate(child: HomeScreen()),
      ),
    ),
  );
}

class TutorialGate extends StatefulWidget {
  final Widget child;

  TutorialGate({required this.child});

  @override
  State<TutorialGate> createState() => _TutorialGateState();
}

class _TutorialGateState extends State<TutorialGate> {
  bool _tutorialOpened = false;

  @override
  Widget build(BuildContext context) {
    final hasSeenTutorial = context.select<AccountProvider, bool>(
      (provider) => provider.hasSeenTutorial,
    );

    if (!hasSeenTutorial && !_tutorialOpened) {
      _tutorialOpened = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        Navigator.of(context).push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => TutorialScreen(),
          ),
        );
      });
    }

    return widget.child;
  }
}

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final accountProvider = context.watch<AccountProvider>();
    final accounts = accountProvider.accounts;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: Text('CashCheetah')),
      drawer: _DashboardDrawer(hasAccounts: accounts.isNotEmpty),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (accounts.isEmpty) {
            showAddAccountDialog(context);
            return;
          }
          showDialog(
            context: context,
            builder: (_) => TransactionForm(),
          );
        },
        child: Icon(accounts.isEmpty ? Icons.add : Icons.add_card),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              accounts.isEmpty
                  ? 'lib/assets/cheetah_kitty_thdev_noAccounts.png'
                  : 'lib/assets/cheetah_kitty_thdev.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            top: false,
            child: ListView(
              padding: EdgeInsets.fromLTRB(12, 0, 12, 96),
              children: [
                DataNoticeBanner(),
                if (accounts.isEmpty)
                  _NoAccountsCard()
                else ...[
                  _DashboardStatsCard(accounts: accounts),
                  _BudgetPlaceholderCard(),
                  _AccountsAccordion(accounts: accounts),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardDrawer extends StatelessWidget {
  final bool hasAccounts;

  _DashboardDrawer({required this.hasAccounts});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: <Widget>[
          ListTile(
            leading: Icon(Icons.add),
            title: Text('Add New Account'),
            onTap: () {
              Navigator.pop(context);
              showAddAccountDialog(context);
            },
          ),
          if (hasAccounts)
            ListTile(
              leading: Icon(Icons.swap_vert),
              title: Text('Manage Accounts'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ManageAccountsScreen()),
                );
              },
            ),
          Divider(),
          ListTile(
            leading: Icon(Icons.bar_chart),
            title: Text('Stats'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => StatsScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.help_outline),
            title: Text('Quick Tour'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) => TutorialScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.settings_outlined),
            title: Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SettingsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NoAccountsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 120),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'No accounts available.\nPlease add an account.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _DashboardStatsCard extends StatelessWidget {
  final List<Account> accounts;

  _DashboardStatsCard({required this.accounts});

  @override
  Widget build(BuildContext context) {
    final stats = _DashboardStats.fromAccounts(accounts);
    return Card(
      margin: EdgeInsets.only(top: 12, bottom: 8),
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: Icon(Icons.bar_chart),
        title: Text('Stats'),
        childrenPadding: EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: [
          GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 2.4,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              _DashboardStatTile(label: 'Cash', value: stats.cashTotalCents),
              _DashboardStatTile(label: 'Debt', value: stats.debtTotalCents),
              _DashboardStatTile(label: 'Net', value: stats.netWorthCents),
              _DashboardStatTile(
                label: 'Spending',
                value: stats.spendingTotalCents,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardStatTile extends StatelessWidget {
  final String label;
  final int value;

  _DashboardStatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(color: Colors.black54)),
          SizedBox(height: 4),
          Text(
            formatCents(value),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _BudgetPlaceholderCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(Icons.savings_outlined),
        title: Text('Budget'),
        subtitle: Text('Budget tools coming soon.'),
      ),
    );
  }
}

class _AccountsAccordion extends StatelessWidget {
  final List<Account> accounts;

  _AccountsAccordion({required this.accounts});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < accounts.length; i++)
          _AccountDashboardCard(account: accounts[i], accountIndex: i),
      ],
    );
  }
}

class _AccountDashboardCard extends StatelessWidget {
  final Account account;
  final int accountIndex;

  _AccountDashboardCard({
    required this.account,
    required this.accountIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Icon(_accountIcon),
        title: Text(account.title),
        subtitle: Text(
          [
            account.accountType.label,
            '${account.accountType.balanceLabel}: ${account.formattedBalance}',
            if (account.formattedAvailableCredit != null)
              'Available: ${account.formattedAvailableCredit}',
          ].join(' - '),
        ),
        childrenPadding: EdgeInsets.only(bottom: 8),
        children: [
          if (account.transactions.isEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('No transactions yet.'),
              ),
            )
          else
            for (int i = 0; i < account.transactions.length; i++)
              _TransactionDashboardRow(
                accountIndex: accountIndex,
                transactionIndex: i,
                transaction: account.transactions[i],
              ),
        ],
      ),
    );
  }

  IconData get _accountIcon {
    switch (account.accountType) {
      case AccountType.bankAccount:
        return Icons.account_balance_wallet_outlined;
      case AccountType.creditCard:
        return Icons.credit_card;
      case AccountType.loan:
        return Icons.request_quote_outlined;
    }
  }
}

class _TransactionDashboardRow extends StatelessWidget {
  final int accountIndex;
  final int transactionIndex;
  final Transaction transaction;

  _TransactionDashboardRow({
    required this.accountIndex,
    required this.transactionIndex,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      title: Text(transaction.description),
      subtitle: Text(
        [
          transaction.action.label,
          transaction.category.label,
          transaction.date.toLocal().toString(),
        ].join(' - '),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(transaction.formattedAmount),
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => TransactionForm(
                  existingTransaction: transaction,
                  transactionIndex: transactionIndex,
                  accountIndex: accountIndex,
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Confirm Delete'),
        content: Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text('Delete'),
            onPressed: () {
              context.read<AccountProvider>().deleteTransactionFromAccount(
                    accountIndex,
                    transactionIndex,
                  );
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}

class _DashboardStats {
  final int cashTotalCents;
  final int debtTotalCents;
  final int spendingTotalCents;

  _DashboardStats({
    required this.cashTotalCents,
    required this.debtTotalCents,
    required this.spendingTotalCents,
  });

  int get netWorthCents => cashTotalCents - debtTotalCents;

  factory _DashboardStats.fromAccounts(List<Account> accounts) {
    var cashTotalCents = 0;
    var debtTotalCents = 0;
    var spendingTotalCents = 0;

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
        if (transaction.countsTowardSpendingStats) {
          spendingTotalCents += transaction.enteredAmountCents;
        }
      }
    }

    return _DashboardStats(
      cashTotalCents: cashTotalCents,
      debtTotalCents: debtTotalCents,
      spendingTotalCents: spendingTotalCents,
    );
  }
}

class DataNoticeBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final notice = context.select<AccountProvider, String?>(
      (provider) => provider.dataNotice,
    );
    if (notice == null) {
      return SizedBox.shrink();
    }

    return SafeArea(
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.all(12),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.amber.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber.shade700),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.amber.shade900),
            SizedBox(width: 8),
            Expanded(child: Text(notice)),
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () =>
                  context.read<AccountProvider>().dismissDataNotice(),
            ),
          ],
        ),
      ),
    );
  }
}
