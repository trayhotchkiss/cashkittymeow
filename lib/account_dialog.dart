import 'package:cashkittymeow/myprovider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void showAddAccountDialog(BuildContext context) {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController balanceController = TextEditingController();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Add New Account'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              TextField(
                controller: titleController,
                decoration: InputDecoration(hintText: "Enter account title"),
              ),
              TextField(
                controller: balanceController,
                decoration: InputDecoration(hintText: "Enter starting balance"),
                keyboardType: TextInputType.numberWithOptions(
                    decimal: true, signed: true), // Allow signed numbers
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('Add'),
            onPressed: () {
              final String title = titleController.text.trim();
              final double? balance =
                  double.tryParse(balanceController.text.trim());
              if (title.isNotEmpty && balance != null) {
                Provider.of<AccountProvider>(context, listen: false)
                    .addAccount(title, balance);
                Navigator.of(context).pop();
              } else {
                // Show an error or do further validation
              }
            },
          ),
        ],
      );
    },
  );
}
