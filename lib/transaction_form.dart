import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'model.dart';
import 'myprovider.dart';

class TransactionForm extends StatefulWidget {
  final Transaction? existingTransaction;
  final int? transactionIndex;

  TransactionForm({this.existingTransaction, this.transactionIndex});

  @override
  _TransactionFormState createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  final _formKey = GlobalKey<FormState>();
  late String _description;
  late String _amountText;
  late TransactionAction _action;
  late TransactionCategory _category;
  late int _enteredAmountCents;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    final transaction = widget.existingTransaction;
    if (transaction != null) {
      _description = transaction.description;
      _amountText = transaction.formattedAmount;
      _action = transaction.action;
      _category = transaction.category;
      _enteredAmountCents = transaction.enteredAmountCents;
      _date = transaction.date;
    } else {
      _description = '';
      _amountText = '';
      _action = TransactionAction.deposit;
      _category = TransactionCategory.other;
      _enteredAmountCents = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = context.watch<AccountProvider>().currentAccount;
    final allowedActions = account?.accountType.transactionActions ??
        AccountType.bankAccount.transactionActions;
    if (!allowedActions.contains(_action)) {
      _action = allowedActions.first;
    }

    return AlertDialog(
      title: Text(widget.existingTransaction != null
          ? 'Edit Transaction'
          : 'Add Transaction'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<TransactionAction>(
                segments: allowedActions
                    .map(
                      (action) => ButtonSegment(
                        value: action,
                        label: Text(action.label),
                      ),
                    )
                    .toList(),
                selected: {_action},
                onSelectionChanged: (selected) {
                  setState(() => _action = selected.first);
                },
              ),
              TextFormField(
                initialValue: _description,
                decoration: InputDecoration(labelText: 'Description'),
                onSaved: (value) => _description = value?.trim() ?? '',
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Please enter a description'
                    : null,
              ),
              TextFormField(
                initialValue: _amountText,
                decoration: InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                onSaved: (value) =>
                    _enteredAmountCents = parseMoneyToCents(value ?? '') ?? 0,
                validator: (value) {
                  final amountText = value?.trim() ?? '';
                  final amountCents = parseMoneyToCents(amountText);
                  if (amountText.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (amountCents == null) {
                    return 'Please enter a valid amount';
                  }
                  if (amountCents <= 0) {
                    return 'Please enter a positive amount';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<TransactionCategory>(
                value: _category,
                decoration: InputDecoration(labelText: 'Category'),
                items: TransactionCategory.values
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category.label),
                      ),
                    )
                    .toList(),
                onChanged: (category) {
                  if (category != null) {
                    setState(() => _category = category);
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          child: Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: Text('Save'),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              final provider =
                  Provider.of<AccountProvider>(context, listen: false);

              if (widget.existingTransaction != null &&
                  widget.transactionIndex != null) {
                provider.updateTransaction(
                  widget.transactionIndex!,
                  _description,
                  _action,
                  _enteredAmountCents,
                  _category,
                  _date,
                );
              } else {
                provider.addTransaction(
                  _description,
                  _action,
                  _enteredAmountCents,
                  _category,
                  _date,
                );
              }

              Navigator.of(context).pop();
            }
          },
        ),
      ],
    );
  }
}
