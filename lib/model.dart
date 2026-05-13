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
        title: json['title'],
        balanceCents: centsFromJson(json, 'balanceCents', 'balance'),
        transactions: (json['transactions'] as List<dynamic>? ?? [])
            .map((t) => Transaction.fromJson(t))
            .toList(),
      );
}

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
        date: DateTime.parse(json['date']),
        description: json['description'],
        amountCents: centsFromJson(json, 'amountCents', 'amount'),
      );
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
