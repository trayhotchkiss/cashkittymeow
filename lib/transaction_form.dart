import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'money_input_formatter.dart';
import 'model.dart';
import 'myprovider.dart';

class TransactionForm extends StatefulWidget {
  final Transaction? existingTransaction;
  final int? transactionIndex;
  final int? accountIndex;

  TransactionForm({
    this.existingTransaction,
    this.transactionIndex,
    this.accountIndex,
  });

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
  late int _selectedAccountIndex;
  DateTime _date = DateTime.now();

  String get _saveButtonText => 'Save ${_action.shortLabel}';

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
      _selectedAccountIndex = widget.accountIndex ?? 0;
      _date = transaction.date;
    } else {
      _description = '';
      _amountText = '';
      _action = TransactionAction.withdrawalPurchase;
      _category = TransactionCategory.other;
      _enteredAmountCents = 0;
      _selectedAccountIndex = widget.accountIndex ?? 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AccountProvider>();
    final accounts = provider.accounts;
    if (accounts.isEmpty) {
      return AlertDialog(
        title: Text('Add Transaction'),
        content: Text('Add an account before entering transactions.'),
        actions: [
          TextButton(
            child: Text('Close'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );
    }

    if (_selectedAccountIndex < 0 || _selectedAccountIndex >= accounts.length) {
      _selectedAccountIndex = 0;
    }

    final account = accounts[_selectedAccountIndex];
    final allowedActions = account.accountType.transactionActions;
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
              DropdownButtonFormField<int>(
                value: _selectedAccountIndex,
                decoration: InputDecoration(labelText: 'Account'),
                items: [
                  for (int i = 0; i < accounts.length; i++)
                    DropdownMenuItem(
                      value: i,
                      child: Text(accounts[i].title),
                    ),
                ],
                onChanged: (index) {
                  if (index == null) {
                    return;
                  }
                  setState(() {
                    _selectedAccountIndex = index;
                    final nextActions = accounts[index].accountType
                        .transactionActions;
                    if (!nextActions.contains(_action)) {
                      _action = nextActions.first;
                    }
                  });
                },
              ),
              SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transaction type',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    SegmentedButton<TransactionAction>(
                      showSelectedIcon: false,
                      segments: allowedActions
                          .map(
                            (action) => ButtonSegment(
                              value: action,
                              label: Text(
                                action.label,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                          .toList(),
                      selected: {_action},
                      onSelectionChanged: (selected) {
                        setState(() => _action = selected.first);
                      },
                    ),
                    SizedBox(height: 8),
                    Text(
                      _action.balancePreviewText,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
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
                keyboardType: TextInputType.text,
                inputFormatters: [
                  MoneyInputFormatter(),
                ],
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
          child: Text(_saveButtonText),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              final provider =
                  Provider.of<AccountProvider>(context, listen: false);

              if (widget.existingTransaction != null &&
                  widget.transactionIndex != null) {
                provider.updateTransactionForAccount(
                  oldAccountIndex: widget.accountIndex ?? _selectedAccountIndex,
                  newAccountIndex: _selectedAccountIndex,
                  transactionIndex: widget.transactionIndex!,
                  newDescription: _description,
                  newAction: _action,
                  newEnteredAmountCents: _enteredAmountCents,
                  newCategory: _category,
                  newDate: _date,
                );
              } else {
                provider.addTransactionToAccount(
                  _selectedAccountIndex,
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
