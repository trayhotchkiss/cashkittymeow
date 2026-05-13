import 'package:flutter/material.dart';
import 'model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AccountProvider with ChangeNotifier {
  List<Account> _accounts = [
    Account(title: "Default Account", balanceCents: 0),
  ];

  int _currentAccountIndex = 0; // Default to the first account

  List<Account> get accounts => _accounts;
  int get currentAccountIndex => _currentAccountIndex;
  Account? get currentAccount {
    if (_accounts.isNotEmpty &&
        _currentAccountIndex >= 0 &&
        _currentAccountIndex < _accounts.length) {
      return _accounts[_currentAccountIndex];
    }
    return null; // Return null or handle it differently if no accounts exist
  }

  Future<void> loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? accountJsonList = prefs.getStringList('accounts');
    if (accountJsonList != null) {
      _accounts = accountJsonList.map((jsonString) {
        return Account.fromJson(jsonDecode(jsonString));
      }).toList();
      _currentAccountIndex = _accounts.isEmpty ? -1 : 0;
      notifyListeners();
    }
  }

  Future<void> saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> accountJsonList =
        _accounts.map((account) => jsonEncode(account.toJson())).toList();
    await prefs.setStringList('accounts', accountJsonList);
  }

  void addAccount(String title, int balanceCents) {
    _accounts.add(Account(title: title, balanceCents: balanceCents));
    setCurrentAccount(_accounts.length - 1);
    saveData(); // Switch to the new account
  }

  void addTransaction(String description, int amountCents, DateTime date) {
    final currentAccount = this.currentAccount;
    if (currentAccount != null) {
      currentAccount.balanceCents += amountCents;
      currentAccount.transactions.add(
        Transaction(
          description: description,
          amountCents: amountCents,
          date: date,
        ),
      );
      notifyListeners(); // Ensure this is called to update UI
      saveData();
    }
  }

  void deleteTransaction(int index) {
    final currentAccount = this.currentAccount;
    if (currentAccount != null &&
        index >= 0 &&
        index < currentAccount.transactions.length) {
      currentAccount.balanceCents -=
          currentAccount.transactions[index].amountCents;
      currentAccount.transactions.removeAt(index);
      notifyListeners();
      saveData();
    }
  }

  void deleteAccount(int index) {
    if (index < 0 || index >= _accounts.length) {
      return;
    }

    // Remove the account at the specified index
    _accounts.removeAt(index);

    // Check if the deleted account was the current account
    if (_currentAccountIndex == index) {
      // If the deleted account was the current account, check if there are any accounts left
      if (_accounts.isEmpty) {
        _currentAccountIndex = -1; // No accounts available
      } else {
        // Set the current account to the first in the list or to the previous one if the last was deleted
        _currentAccountIndex =
            index == _accounts.length ? _accounts.length - 1 : index;
      }
    } else if (index < _currentAccountIndex) {
      // If the deleted account was before the current account, adjust the index
      _currentAccountIndex--;
    }

    notifyListeners();
    saveData();
  }

  void setCurrentAccount(int index) {
    if (index >= 0 && index < _accounts.length) {
      _currentAccountIndex = index;
      notifyListeners();
    }
  }

  void updateTransaction(
      int index, String newDescription, int newAmountCents, DateTime newDate) {
    final currentAccount = this.currentAccount;
    if (currentAccount != null &&
        index >= 0 &&
        index < currentAccount.transactions.length) {
      final oldTransaction = currentAccount.transactions[index];

      // Adjust balance: remove old amount, add new amount
      currentAccount.balanceCents -= oldTransaction.amountCents;
      currentAccount.balanceCents += newAmountCents;

      // Update the transaction itself
      currentAccount.transactions[index] = Transaction(
        description: newDescription,
        amountCents: newAmountCents,
        date: newDate,
      );

      notifyListeners();
      saveData();
    }
  }
}
