import 'package:flutter/material.dart';
import 'model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AccountProvider with ChangeNotifier {
  List<Account> _accounts = [Account(title: "Default Account", balance: 0.0)];
  List<Transaction> transactions = [];

  int _currentAccountIndex = 0; // Default to the first account

  List<Account> get accounts => _accounts;
  int get currentAccountIndex => _currentAccountIndex;
  Account? get currentAccount {
    if (_accounts.isNotEmpty) {
      return _accounts[_currentAccountIndex];
    }
    return null; // Return null or handle it differently if no accounts exist
  }

  Future<void> loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? accountJsonList = prefs.getStringList('accounts');
    if (accountJsonList != null && accountJsonList.isNotEmpty) {
      _accounts = accountJsonList.map((jsonString) {
        return Account.fromJson(jsonDecode(jsonString));
      }).toList();
      _currentAccountIndex = 0; // Reset to first account on load
      notifyListeners();
    }
  }

  void saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> accountJsonList =
        _accounts.map((account) => jsonEncode(account.toJson())).toList();
    await prefs.setStringList('accounts', accountJsonList);
  }

  void addAccount(String title, double balance) {
    _accounts.add(Account(title: title, balance: balance));
    setCurrentAccount(_accounts.length - 1);
    saveData(); // Switch to the new account
  }

  void addTransaction(String description, double amount, DateTime date) {
    final currentAccount = this.currentAccount;
    if (currentAccount != null) {
      print(
          "Current transactions count: ${currentAccount.transactions.length}");
      try {
        // Update the balance first
        currentAccount.balance +=
            amount; // Assuming 'amount' can be negative or positive based on the transaction type

        // Then add the transaction
        currentAccount.transactions.add(
            Transaction(description: description, amount: amount, date: date));
        print(
            "Transaction added. New count: ${currentAccount.transactions.length}");
      } catch (e) {
        print("Failed to add transaction: $e");
      }
      notifyListeners(); // Ensure this is called to update UI
      saveData();
    } else {
      print("No current account selected");
    }
  }

  void deleteTransaction(int index) {
    final currentAccount = this.currentAccount;
    if (currentAccount != null) {
      currentAccount.balance -= currentAccount.transactions[index].amount;
      currentAccount.transactions.removeAt(index);
      notifyListeners();
      saveData();
    }
  }

  void editTransaction(
      int index, String description, double amount, DateTime date) {
    final currentAccount = this.currentAccount;
    if (currentAccount != null &&
        index >= 0 &&
        index < currentAccount.transactions.length) {
      currentAccount.transactions[index] = Transaction(
        description: description,
        amount: amount,
        date: date,
      );
      notifyListeners();
      saveData();
    }
  }

  void deleteAccount(int index) {
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
    _currentAccountIndex = index;
    notifyListeners();
  }

  void updateTransaction(
      int index, String newDescription, double newAmount, DateTime newDate) {
    final currentAccount = this.currentAccount;
    if (currentAccount != null) {
      final oldTransaction = currentAccount.transactions[index];

      // Adjust balance: remove old amount, add new amount
      currentAccount.balance -= oldTransaction.amount;
      currentAccount.balance += newAmount;

      // Update the transaction itself
      currentAccount.transactions[index] = Transaction(
        description: newDescription,
        amount: newAmount,
        date: newDate,
      );

      notifyListeners();
    }
  }
}
