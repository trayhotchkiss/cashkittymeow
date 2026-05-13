import 'package:cashkittymeow/myprovider.dart';
import 'package:cashkittymeow/model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void showAddAccountDialog(BuildContext context) {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController balanceController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Add New Account'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextFormField(
                  controller: titleController,
                  decoration: InputDecoration(hintText: "Enter account title"),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Please enter an account title'
                      : null,
                ),
                TextFormField(
                  controller: balanceController,
                  decoration:
                      InputDecoration(hintText: "Enter starting balance"),
                  keyboardType: TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  validator: (value) {
                    final balanceText = value?.trim() ?? '';
                    if (balanceText.isEmpty) {
                      return 'Please enter a starting balance';
                    }
                    if (parseMoneyToCents(balanceText) == null) {
                      return 'Please enter a valid balance';
                    }
                    return null;
                  },
                ),
              ],
            ),
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
              if (!formKey.currentState!.validate()) {
                return;
              }
              final String title = titleController.text.trim();
              final int balanceCents =
                  parseMoneyToCents(balanceController.text) ?? 0;
              Provider.of<AccountProvider>(context, listen: false)
                  .addAccount(title, balanceCents);
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
