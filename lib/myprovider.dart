import 'package:flutter/material.dart';
import 'model.dart';

class AccountProvider with ChangeNotifier {
  List<Account> _accounts = [];

  List<Account> get accounts => _accounts;

  void addAccount(String title, double balance) {
    _accounts.add(Account(title: title, balance: balance));
    notifyListeners();
  }

  void addTransaction(int accountIndex, String description, double amount) {
    var transaction = Transaction(
        date: DateTime.now(), description: description, amount: amount);
    _accounts[accountIndex].transactions.add(transaction);
    _accounts[accountIndex].balance += amount;
    notifyListeners();
  }
}
