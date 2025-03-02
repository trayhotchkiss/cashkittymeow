import 'package:flutter/material.dart';
import 'model.dart';

class AccountProvider with ChangeNotifier {
  List<Account> _accounts = [];
  int _currentAccountIndex = 0; // Default to the first account

  List<Account> get accounts => _accounts;
  int get currentAccountIndex => _currentAccountIndex;
  Account get currentAccount => _accounts[_currentAccountIndex];

  void addAccount(String title, double balance) {
    _accounts.add(Account(title: title, balance: balance));
    setCurrentAccount(_accounts.length - 1); // Switch to the new account
  }

  void addTransaction(String description, double amount) {
    var transaction = Transaction(
        date: DateTime.now(), description: description, amount: amount);
    _accounts[_currentAccountIndex].transactions.add(transaction);
    _accounts[_currentAccountIndex].balance += amount;
    notifyListeners();
  }

  void setCurrentAccount(int index) {
    _currentAccountIndex = index;
    notifyListeners();
  }
}
