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
  late double _amount;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.existingTransaction != null) {
      _description = widget.existingTransaction!.description;
      _amount = widget.existingTransaction!.amount;
      _date = widget.existingTransaction!.date;
    } else {
      _description = '';
      _amount = 0.0;
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
              onSaved: (value) => _description = value ?? '',
              validator: (value) => (value == null || value.isEmpty)
                  ? 'Please enter a description'
                  : null,
            ),
            TextFormField(
              initialValue: _amount.toString(),
              decoration: InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.number,
              onSaved: (value) => _amount = double.tryParse(value ?? '') ?? 0.0,
              validator: (value) => (value == null || value.isEmpty)
                  ? 'Please enter an amount'
                  : null,
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
                    widget.transactionIndex!, _description, _amount, _date);
              } else {
                provider.addTransaction(_description, _amount, _date);
              }

              Navigator.of(context).pop();
            }
          },
        ),
      ],
    );
  }
}
