import 'package:flutter/material.dart';
import 'myprovider.dart';
import 'package:provider/provider.dart';
import 'account_dialog.dart';
import 'model.dart';
import 'settings_screen.dart';
import 'transaction_form.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) {
        final provider = AccountProvider();
        provider.loadData();
        return provider;
      },
      child: MaterialApp(home: HomeScreen()),
    ),
  );
}

// widget to define the HomeScreen
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var accountProvider =
        Provider.of<AccountProvider>(context); // access the accountprovider
    var account = accountProvider.currentAccount; // current selected account

    if (account == null) {
      // Display a message or alternative UI when no accounts exist
      return Scaffold(
        appBar: AppBar(title: Text('CashCheetah')),
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'lib/assets/cashKittyCheetah.png', // ✅ Use your image path here
                fit: BoxFit.cover,
              ),
            ),
            Center(
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
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
              ),
            ),
            DataNoticeBanner(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showAddAccountDialog(context);
          },
          child: Icon(Icons.add),
        ),
        drawer: Drawer(
          child: ListView(
            children: <Widget>[
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
        ),
      );
    } else {
      // UI when account
      return Scaffold(
        appBar: AppBar(title: Text('CashCheetah')),
        drawer: Drawer(
          child: ListView(
            children: <Widget>[
              for (int i = 0; i < accountProvider.accounts.length; i++)
                ListTile(
                  title: Text(accountProvider.accounts[i].title),
                  subtitle: Text(accountProvider.accounts[i].accountType.label),
                  onTap: () {
                    accountProvider.setCurrentAccount(i);
                    Navigator.pop(context); // Close the drawer after selection
                  },
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text("Confirm"),
                            content: Text(
                                "Are you sure you want to delete this account?"),
                            actions: <Widget>[
                              TextButton(
                                child: Text("Cancel"),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                              TextButton(
                                child: Text("Delete"),
                                onPressed: () {
                                  accountProvider.deleteAccount(i);
                                  Navigator.of(context)
                                      .pop(); // Close the dialog
                                  Navigator.of(context)
                                      .pop(); // Close the drawer
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ListTile(
                leading: Icon(Icons.add),
                title: Text('Add New Account'),
                onTap: () => showAddAccountDialog(context),
              ),
              Divider(),
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
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => TransactionForm(),
            ); // Logic to add a new transaction
          },
          child: Icon(Icons.add),
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'lib/assets/cashKittyDS.png', // ✅ Make sure this path matches your file
                fit: BoxFit.cover,
              ),
            ),
            Column(
              children: <Widget>[
                DataNoticeBanner(),
                CategoryStatsPanel(account: accountProvider.currentAccount!),
                Expanded(
                  child: ListView.builder(
                    itemCount:
                        accountProvider.currentAccount!.transactions.length,
                    itemBuilder: (context, index) {
                      var transaction =
                          accountProvider.currentAccount!.transactions[index];
                      return Container(
                        color: index.isEven
                            ? Colors.white.withOpacity(0.8)
                            : Colors.grey[300]?.withOpacity(0.8),
                        child: ListTile(
                          title: Text(transaction.description),
                          subtitle: Text(
                            [
                              transaction.action.label,
                              transaction.category.label,
                              '${transaction.formattedAmount} on ${transaction.date.toLocal()}',
                            ].join(' - '),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => TransactionForm(
                                      existingTransaction: transaction,
                                      transactionIndex: index,
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: Text('Confirm Delete'),
                                      content: Text(
                                          'Are you sure you want to delete this transaction?'),
                                      actions: [
                                        TextButton(
                                          child: Text('Cancel'),
                                          onPressed: () =>
                                              Navigator.of(context).pop(),
                                        ),
                                        TextButton(
                                          child: Text('Delete'),
                                          onPressed: () {
                                            accountProvider
                                                .deleteTransaction(index);
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  color: Colors.white.withOpacity(0.9),
                  padding: EdgeInsets.all(16),
                  child: Text(
                    [
                      accountProvider.currentAccount!.accountType.balanceLabel,
                      accountProvider.currentAccount!.formattedBalance,
                    ].join(': '),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
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

class CategoryStatsPanel extends StatelessWidget {
  final Account account;

  CategoryStatsPanel({required this.account});

  @override
  Widget build(BuildContext context) {
    final totalsByCategory = <TransactionCategory, int>{};
    for (final transaction in account.transactions) {
      if (!transaction.countsTowardSpendingStats) {
        continue;
      }
      totalsByCategory.update(
        transaction.category,
        (total) => total + transaction.enteredAmountCents,
        ifAbsent: () => transaction.enteredAmountCents,
      );
    }

    final sortedTotals = totalsByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final totalSpending =
        sortedTotals.fold<int>(0, (total, entry) => total + entry.value);

    return Container(
      width: double.infinity,
      color: Colors.white.withOpacity(0.9),
      padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spending: ${formatCents(totalSpending)}',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 6),
          if (sortedTotals.isEmpty)
            Text('No spending categories yet.')
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: sortedTotals.take(4).map((entry) {
                return Chip(
                  label: Text(
                    '${entry.key.label}: ${formatCents(entry.value)}',
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
