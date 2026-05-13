import 'dart:convert';

class Account {
  String title;
  int balanceCents;
  List<Transaction> transactions;

  Account({
    required this.title,
    required this.balanceCents,
    List<Transaction>? transactions,
  }) : transactions = transactions ?? [];

  String get formattedBalance => formatCents(balanceCents);

  Map<String, dynamic> toJson() => {
        'title': title,
        'balanceCents': balanceCents,
        'transactions': transactions.map((t) => t.toJson()).toList(),
      };

  factory Account.fromJson(Map<String, dynamic> json) => Account(
        title: stringFromJson(json['title'], fallback: 'Untitled Account'),
        balanceCents: centsFromJson(json, 'balanceCents', 'balance'),
        transactions: transactionsFromJson(json['transactions']),
      );
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
  int amountCents;

  Transaction({
    required this.date,
    required this.description,
    required this.amountCents,
  });

  String get formattedAmount => formatCents(amountCents);

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'description': description,
        'amountCents': amountCents,
      };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        date: dateTimeFromJson(json['date']),
        description:
            stringFromJson(json['description'], fallback: 'Untitled Transaction'),
        amountCents: centsFromJson(json, 'amountCents', 'amount'),
      );
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
