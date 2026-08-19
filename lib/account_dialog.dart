import 'package:cashcheetah/myprovider.dart';
import 'package:cashcheetah/model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'money_input_formatter.dart';

void showAddAccountDialog(BuildContext context) {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController balanceController = TextEditingController();
  final TextEditingController creditLimitController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  AccountType selectedAccountType = AccountType.bankAccount;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Add New Account'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  TextFormField(
                    controller: titleController,
                    decoration: InputDecoration(hintText: "Enter account title"),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                            ? 'Please enter an account title'
                            : null,
                  ),
                  SizedBox(height: 12),
                  DropdownButtonFormField<AccountType>(
                    value: selectedAccountType,
                    decoration: InputDecoration(labelText: 'Account type'),
                    items: AccountType.values
                        .map(
                          (accountType) => DropdownMenuItem(
                            value: accountType,
                            child: Text(accountType.label),
                          ),
                        )
                        .toList(),
                    onChanged: (accountType) {
                      if (accountType != null) {
                        setState(() {
                          selectedAccountType = accountType;
                          if (selectedAccountType != AccountType.bankAccount &&
                              balanceController.text.startsWith('-')) {
                            balanceController.text =
                                balanceController.text.substring(1);
                          }
                        });
                      }
                    },
                  ),
                  TextFormField(
                    controller: balanceController,
                    decoration:
                        InputDecoration(hintText: "Enter starting balance"),
                    keyboardType: TextInputType.text,
                    inputFormatters: [
                      MoneyInputFormatter(
                        allowNegative:
                            selectedAccountType == AccountType.bankAccount,
                      ),
                    ],
                    validator: (value) {
                      final balanceText = value?.trim() ?? '';
                      if (balanceText.isEmpty) {
                        return 'Please enter a starting balance';
                      }
                      final balanceCents = parseMoneyToCents(balanceText);
                      if (balanceCents == null) {
                        return 'Please enter a valid balance';
                      }
                      if (selectedAccountType != AccountType.bankAccount &&
                          balanceCents < 0) {
                        return 'Please enter a positive owed balance';
                      }
                      return null;
                    },
                  ),
                  if (selectedAccountType == AccountType.creditCard) ...[
                    SizedBox(height: 12),
                    TextFormField(
                      controller: creditLimitController,
                      decoration:
                          InputDecoration(hintText: "Enter credit limit"),
                      keyboardType: TextInputType.text,
                      inputFormatters: [
                        MoneyInputFormatter(),
                      ],
                      validator: (value) {
                        final limitText = value?.trim() ?? '';
                        if (limitText.isEmpty) {
                          return 'Please enter a credit limit';
                        }
                        final limitCents = parseMoneyToCents(limitText);
                        if (limitCents == null || limitCents <= 0) {
                          return 'Please enter a valid credit limit';
                        }
                        return null;
                      },
                    ),
                  ],
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
                final int? creditLimitCents =
                    selectedAccountType == AccountType.creditCard
                        ? parseMoneyToCents(creditLimitController.text)
                        : null;
                Provider.of<AccountProvider>(context, listen: false)
                    .addAccount(
                  title,
                  selectedAccountType,
                  balanceCents,
                  creditLimitCents: creditLimitCents,
                );
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
    },
  );
}
