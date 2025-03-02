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
            for (var account in accountProvider.accounts)
              ListTile(
                title: Text(account.title),
                onTap: () {
                  // logic to switch account view
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
      body: ListView(
        children: accountProvider.accounts
            .map((account) => ListTile(
                  title: Text(account.title),
                  subtitle:
                      Text('Balance: \$${account.balance.toStringAsFixed(2)}'),
                ))
            .toList(),
      ),
    );
  }
}
