import 'package:flutter/material.dart';
import 'myprovider.dart';
import 'package:provider/provider.dart';
import 'account_dialog.dart';
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
      child: MaterialApp(home: TutorialGate(child: HomeScreen())),
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
        resizeToAvoidBottomInset: true,
        appBar: AppBar(title: Text('CashCheetah')),
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'lib/assets/cheetah_kitty_thdev_noAccounts.png',
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
        ),
      );
    } else {
      // UI when account
      return Scaffold(
        resizeToAvoidBottomInset: true,
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
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'lib/assets/cheetah_kitty_thdev.png',
                fit: BoxFit.cover,
              ),
            ),
            Column(
              children: <Widget>[
                DataNoticeBanner(),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.only(bottom: 76),
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
                  width: double.infinity,
                  color: Colors.white.withOpacity(0.9),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Text(
                        [
                          accountProvider
                              .currentAccount!.accountType.balanceLabel,
                          accountProvider.currentAccount!.formattedBalance,
                        ].join(': '),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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
