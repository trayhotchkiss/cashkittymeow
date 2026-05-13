import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'model.dart';

class AccountProvider with ChangeNotifier {
  List<Account> _accounts = [
    Account(title: "Default Account", balanceCents: 0),
  ];

  int _currentAccountIndex = 0; // Default to the first account
  String? _dataNotice;
  bool _hasSeenTutorial = true;

  List<Account> get accounts => _accounts;
  int get currentAccountIndex => _currentAccountIndex;
  String? get dataNotice => _dataNotice;
  bool get hasSeenTutorial => _hasSeenTutorial;
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
    _hasSeenTutorial = prefs.getBool('hasSeenTutorial') ?? false;
    List<String>? accountJsonList = prefs.getStringList('accounts');
    if (accountJsonList != null) {
      _accounts = recoverAccountsFromStoredJsonList(accountJsonList);
      _currentAccountIndex = _accounts.isEmpty ? -1 : 0;
      if (_accounts.length != accountJsonList.length) {
        _dataNotice =
            'Some saved data could not be loaded and was skipped.';
        await saveData();
      } else {
        _dataNotice = null;
      }
      notifyListeners();
    } else {
      notifyListeners();
    }
  }

  Future<void> completeTutorial() async {
    _hasSeenTutorial = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenTutorial', true);
  }

  Future<void> resetTutorial() async {
    _hasSeenTutorial = false;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenTutorial', false);
  }

  void dismissDataNotice() {
    if (_dataNotice == null) {
      return;
    }
    _dataNotice = null;
    notifyListeners();
  }

  Future<void> saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> accountJsonList =
        _accounts.map((account) => jsonEncode(account.toJson())).toList();
    await prefs.setStringList('accounts', accountJsonList);
  }

  void addAccount(String title, AccountType accountType, int balanceCents) {
    _accounts.add(
      Account(
        title: title,
        accountType: accountType,
        balanceCents: balanceCents,
      ),
    );
    setCurrentAccount(_accounts.length - 1);
    saveData(); // Switch to the new account
  }

  void addTransaction(
    String description,
    TransactionAction action,
    int enteredAmountCents,
    TransactionCategory category,
    DateTime date,
  ) {
    final currentAccount = this.currentAccount;
    if (currentAccount != null) {
      final amountCents = balanceEffectCents(action, enteredAmountCents);
      currentAccount.balanceCents += amountCents;
      currentAccount.transactions.add(
        Transaction(
          description: description,
          action: action,
          category: category,
          amountCents: amountCents,
          date: date,
        ),
      );
      notifyListeners(); // Ensure this is called to update UI
      saveData();
    }
  }

  String exportBackupJson() {
    return JsonEncoder.withIndent('  ')
        .convert(backupJsonFromAccounts(_accounts));
  }

  Future<void> replaceAllAccountsFromBackupJson(String backupJson) async {
    final decodedJson = jsonDecode(backupJson);
    final backupMap = mapFromJson(decodedJson);
    if (backupMap == null) {
      throw FormatException('The backup file is not valid JSON.');
    }

    _accounts = accountsFromBackupJson(backupMap);
    _currentAccountIndex = _accounts.isEmpty ? -1 : 0;
    _dataNotice = null;
    notifyListeners();
    await saveData();
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
    int index,
    String newDescription,
    TransactionAction newAction,
    int newEnteredAmountCents,
    TransactionCategory newCategory,
    DateTime newDate,
  ) {
    final currentAccount = this.currentAccount;
    if (currentAccount != null &&
        index >= 0 &&
        index < currentAccount.transactions.length) {
      final oldTransaction = currentAccount.transactions[index];

      // Adjust balance: remove old amount, add new amount
      currentAccount.balanceCents -= oldTransaction.amountCents;
      final newAmountCents =
          balanceEffectCents(newAction, newEnteredAmountCents);
      currentAccount.balanceCents += newAmountCents;

      // Update the transaction itself
      currentAccount.transactions[index] = Transaction(
        description: newDescription,
        action: newAction,
        category: newCategory,
        amountCents: newAmountCents,
        date: newDate,
      );

      notifyListeners();
      saveData();
    }
  }
}
