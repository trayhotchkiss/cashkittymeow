import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'myprovider.dart';
import 'model.dart';

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
  late int _amountCents;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.existingTransaction != null) {
      _description = widget.existingTransaction!.description;
      _amountText = widget.existingTransaction!.formattedAmount;
      _amountCents = widget.existingTransaction!.amountCents;
      _date = widget.existingTransaction!.date;
    } else {
      _description = '';
      _amountText = '';
      _amountCents = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existingTransaction != null
          ? 'Edit Transaction'
          : 'Add Transaction'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
              keyboardType:
                  TextInputType.numberWithOptions(decimal: true, signed: true),
              onSaved: (value) =>
                  _amountCents = parseMoneyToCents(value ?? '') ?? 0,
              validator: (value) {
                final amountText = value?.trim() ?? '';
                if (amountText.isEmpty) {
                  return 'Please enter an amount';
                }
                if (parseMoneyToCents(amountText) == null) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
            ),
            // Optional: Add date picker here if desired
          ],
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
              var provider =
                  Provider.of<AccountProvider>(context, listen: false);

              if (widget.existingTransaction != null &&
                  widget.transactionIndex != null) {
                provider.updateTransaction(
                  widget.transactionIndex!,
                  _description,
                  _amountCents,
                  _date,
                );
              } else {
                provider.addTransaction(_description, _amountCents, _date);
              }

              Navigator.of(context).pop();
            }
          },
        ),
      ],
    );
  }
}
