import 'package:flutter/material.dart';
import 'myprovider.dart';
import 'package:provider/provider.dart';
import 'account_dialog.dart';

void main() {
  runApp(ChangeNotifierProvider(
    create: (context) => AccountProvider(),
    child: MaterialApp(home: HomeScreen()),
  ));
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var accountProvider = Provider.of<AccountProvider>(context);
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
          // Logic to add a new transaction
        },
        child: Icon(Icons.add),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              children: accountProvider.currentAccount.transactions
                  .map((transaction) => ListTile(
                        title: Text(transaction.description),
                        subtitle: Text(
                            '${transaction.amount} on ${transaction.date}'),
                      ))
                  .toList(),
            ),
          ),
          Text(
              'Total Balance: ${accountProvider.currentAccount.balance.toStringAsFixed(2)}'),
        ],
      ),
    );
  }
}
