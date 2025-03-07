import 'package:flutter/material.dart';
import 'myprovider.dart';
import 'package:provider/provider.dart';
import 'account_dialog.dart';
import 'transaction.dart';
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
        appBar: AppBar(title: Text('Cash Kitty')),
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'lib/assets/cashKittyDS.png', // ✅ Use your image path here
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
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showAddAccountDialog(context);
          },
          child: Icon(Icons.add),
        ),
      );
    } else {
      // UI when account
      return Scaffold(
        appBar: AppBar(title: Text('Cash Kitty')),
        drawer: Drawer(
          child: ListView(
            children: <Widget>[
              for (int i = 0; i < accountProvider.accounts.length; i++)
                ListTile(
                  title: Text(accountProvider.accounts[i].title),
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
                'lib/assets/cashKittyCheetah.png', // ✅ Make sure this path matches your file
                fit: BoxFit.cover,
              ),
            ),
            Column(
              children: <Widget>[
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
                              '${transaction.amount} on ${transaction.date.toLocal()}'),
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
                    'Total Balance: ${accountProvider.currentAccount!.balance.toStringAsFixed(2)}',
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
