import 'dart:convert';

class Account {
  String title;
  AccountType accountType;
  int balanceCents;
  List<Transaction> transactions;

  Account({
    required this.title,
    this.accountType = AccountType.bankAccount,
    required this.balanceCents,
    List<Transaction>? transactions,
  }) : transactions = transactions ?? [];

  String get formattedBalance => formatCents(balanceCents);

  Map<String, dynamic> toJson() => {
        'title': title,
        'accountType': accountType.storageKey,
        'balanceCents': balanceCents,
        'transactions': transactions.map((t) => t.toJson()).toList(),
      };

  factory Account.fromJson(Map<String, dynamic> json) => Account(
        title: stringFromJson(json['title'], fallback: 'Untitled Account'),
        accountType: accountTypeFromJson(json['accountType']),
        balanceCents: centsFromJson(json, 'balanceCents', 'balance'),
        transactions: transactionsFromJson(json['transactions']),
      );
}

enum AccountType {
  bankAccount,
  creditCard,
  loan,
}

extension AccountTypeValues on AccountType {
  String get label {
    switch (this) {
      case AccountType.bankAccount:
        return 'Bank Account';
      case AccountType.creditCard:
        return 'Credit Card';
      case AccountType.loan:
        return 'Loan';
    }
  }

  String get storageKey {
    switch (this) {
      case AccountType.bankAccount:
        return 'bankAccount';
      case AccountType.creditCard:
        return 'creditCard';
      case AccountType.loan:
        return 'loan';
    }
  }

  String get balanceLabel {
    switch (this) {
      case AccountType.bankAccount:
        return 'Balance';
      case AccountType.creditCard:
      case AccountType.loan:
        return 'Amount Owed';
    }
  }

  List<TransactionAction> get transactionActions {
    switch (this) {
      case AccountType.bankAccount:
        return [
          TransactionAction.deposit,
          TransactionAction.withdrawalPurchase,
        ];
      case AccountType.creditCard:
      case AccountType.loan:
        return [
          TransactionAction.payment,
          TransactionAction.charge,
        ];
    }
  }
}

AccountType accountTypeFromJson(dynamic value) {
  switch (value) {
    case 'creditCard':
      return AccountType.creditCard;
    case 'loan':
      return AccountType.loan;
    case 'bankAccount':
    default:
      return AccountType.bankAccount;
  }
}

List<Account> accountsFromBackupJson(Map<String, dynamic> backupJson) {
  if (backupJson['format'] != 'cashcheetah.backup') {
    throw FormatException('This is not a CashCheetah backup file.');
  }

  final version = backupJson['version'];
  if (version != 1) {
    throw FormatException('This backup version is not supported.');
  }

  final accountsJson = backupJson['accounts'];
  if (accountsJson is! List) {
    throw FormatException('The backup file does not contain accounts.');
  }

  return accountsJson.map((accountJson) {
    final accountMap = mapFromJson(accountJson);
    if (accountMap == null) {
      throw FormatException('The backup contains an invalid account.');
    }
    return Account.fromJson(accountMap);
  }).toList();
}

List<Account> recoverAccountsFromStoredJsonList(List<String> accountJsonList) {
  final accounts = <Account>[];

  for (final accountJson in accountJsonList) {
    try {
      final decodedJson = accountJson.isEmpty ? null : jsonDecode(accountJson);
      final accountMap = mapFromJson(decodedJson);
      if (accountMap != null) {
        accounts.add(Account.fromJson(accountMap));
      }
    } catch (_) {
      continue;
    }
  }

  return accounts;
}

List<Transaction> transactionsFromJson(dynamic transactionsJson) {
  if (transactionsJson is! List) {
    return [];
  }

  return transactionsJson
      .map(mapFromJson)
      .whereType<Map<String, dynamic>>()
      .map(Transaction.fromJson)
      .toList();
}

Map<String, dynamic>? mapFromJson(dynamic value) {
  if (value is! Map) {
    return null;
  }

  return value.map((key, mapValue) => MapEntry(key.toString(), mapValue));
}

Map<String, dynamic> backupJsonFromAccounts(List<Account> accounts) => {
      'format': 'cashcheetah.backup',
      'version': 1,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'accounts': accounts.map((account) => account.toJson()).toList(),
    };

class Transaction {
  DateTime date;
  String description;
  TransactionAction action;
  TransactionCategory category;
  int amountCents;

  Transaction({
    required this.date,
    required this.description,
    this.action = TransactionAction.deposit,
    this.category = TransactionCategory.other,
    required this.amountCents,
  });

  int get enteredAmountCents => amountCents.abs();
  String get formattedAmount => formatCents(enteredAmountCents);
  bool get countsTowardSpendingStats =>
      action == TransactionAction.withdrawalPurchase ||
      action == TransactionAction.charge;

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'description': description,
        'action': action.storageKey,
        'category': category.storageKey,
        'amountCents': amountCents,
      };

  factory Transaction.fromJson(Map<String, dynamic> json) {
    final amountCents = centsFromJson(json, 'amountCents', 'amount');
    return Transaction(
      date: dateTimeFromJson(json['date']),
      description:
          stringFromJson(json['description'], fallback: 'Untitled Transaction'),
      action: transactionActionFromJson(
        json['action'],
        amountCents: amountCents,
      ),
      category: transactionCategoryFromJson(json['category']),
      amountCents: amountCents,
    );
  }
}

enum TransactionAction {
  deposit,
  withdrawalPurchase,
  payment,
  charge,
}

extension TransactionActionValues on TransactionAction {
  String get label {
    switch (this) {
      case TransactionAction.deposit:
        return 'Deposit';
      case TransactionAction.withdrawalPurchase:
        return 'Withdrawal/Purchase';
      case TransactionAction.payment:
        return 'Payment';
      case TransactionAction.charge:
        return 'Charge';
    }
  }

  String get storageKey {
    switch (this) {
      case TransactionAction.deposit:
        return 'deposit';
      case TransactionAction.withdrawalPurchase:
        return 'withdrawalPurchase';
      case TransactionAction.payment:
        return 'payment';
      case TransactionAction.charge:
        return 'charge';
    }
  }
}

TransactionAction transactionActionFromJson(
  dynamic value, {
  required int amountCents,
}) {
  switch (value) {
    case 'withdrawalPurchase':
      return TransactionAction.withdrawalPurchase;
    case 'payment':
      return TransactionAction.payment;
    case 'charge':
      return TransactionAction.charge;
    case 'deposit':
      return TransactionAction.deposit;
    default:
      return amountCents < 0
          ? TransactionAction.withdrawalPurchase
          : TransactionAction.deposit;
  }
}

enum TransactionCategory {
  food,
  bills,
  gas,
  shopping,
  entertainment,
  fees,
  rent,
  paycheck,
  other,
}

extension TransactionCategoryValues on TransactionCategory {
  String get label {
    switch (this) {
      case TransactionCategory.food:
        return 'Food';
      case TransactionCategory.bills:
        return 'Bills';
      case TransactionCategory.gas:
        return 'Gas';
      case TransactionCategory.shopping:
        return 'Shopping';
      case TransactionCategory.entertainment:
        return 'Entertainment';
      case TransactionCategory.fees:
        return 'Fees';
      case TransactionCategory.rent:
        return 'Rent';
      case TransactionCategory.paycheck:
        return 'Paycheck';
      case TransactionCategory.other:
        return 'Other';
    }
  }

  String get storageKey {
    switch (this) {
      case TransactionCategory.food:
        return 'food';
      case TransactionCategory.bills:
        return 'bills';
      case TransactionCategory.gas:
        return 'gas';
      case TransactionCategory.shopping:
        return 'shopping';
      case TransactionCategory.entertainment:
        return 'entertainment';
      case TransactionCategory.fees:
        return 'fees';
      case TransactionCategory.rent:
        return 'rent';
      case TransactionCategory.paycheck:
        return 'paycheck';
      case TransactionCategory.other:
        return 'other';
    }
  }
}

TransactionCategory transactionCategoryFromJson(dynamic value) {
  for (final category in TransactionCategory.values) {
    if (category.storageKey == value) {
      return category;
    }
  }
  return TransactionCategory.other;
}

int balanceEffectCents(TransactionAction action, int positiveAmountCents) {
  final amount = positiveAmountCents.abs();
  switch (action) {
    case TransactionAction.deposit:
    case TransactionAction.charge:
      return amount;
    case TransactionAction.withdrawalPurchase:
    case TransactionAction.payment:
      return -amount;
  }
}

DateTime dateTimeFromJson(dynamic value) {
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }
  return DateTime.now();
}

String stringFromJson(dynamic value, {required String fallback}) {
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }
  return fallback;
}

int centsFromJson(
  Map<String, dynamic> json,
  String centsKey,
  String legacyDecimalKey,
) {
  final centsValue = json[centsKey];
  if (centsValue is int) {
    return centsValue;
  }
  if (centsValue is num) {
    return centsValue.round();
  }

  final legacyValue = json[legacyDecimalKey];
  if (legacyValue is num) {
    return (legacyValue * 100).round();
  }
  if (legacyValue is String) {
    return parseMoneyToCents(legacyValue) ?? 0;
  }
  return 0;
}

int? parseMoneyToCents(String value) {
  final normalized = value.trim().replaceAll(',', '');
  final match = RegExp(r'^([+-]?)(?:(\d+)(?:\.(\d{0,2}))?|\.(\d{1,2}))$')
      .firstMatch(normalized);
  if (match == null) {
    return null;
  }

  final sign = match.group(1) == '-' ? -1 : 1;
  final wholePart = match.group(2) ?? '0';
  final decimalPart = (match.group(3) ?? match.group(4) ?? '').padRight(2, '0');
  return sign * ((int.parse(wholePart) * 100) + int.parse(decimalPart));
}

String formatCents(int cents) {
  final sign = cents < 0 ? '-' : '';
  final absoluteCents = cents.abs();
  final dollars = absoluteCents ~/ 100;
  final centsRemainder = (absoluteCents % 100).toString().padLeft(2, '0');
  return '$sign$dollars.$centsRemainder';
}
