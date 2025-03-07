// For encoding and decoding JSON

class Transaction {
  String description;
  double amount;
  DateTime date;

  Transaction({
    required this.description,
    required this.amount,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'description': description,
        'amount': amount,
        'date': date.toIso8601String(),
      };

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      description: json['description'],
      amount: json['amount'],
      date: DateTime.parse(json['date']),
    );
  }
}

class Account {
  String title;
  double balance;
  List<Transaction> transactions;

  Account({
    required this.title,
    required this.balance,
    List<Transaction>? transactions,
  }) : transactions = transactions ?? [];

  Map<String, dynamic> toJson() => {
        'title': title,
        'balance': balance,
        'transactions': transactions.map((t) => t.toJson()).toList(),
      };

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      title: json['title'],
      balance: json['balance'],
      transactions: (json['transactions'] as List)
          .map((t) => Transaction.fromJson(t))
          .toList(),
    );
  }
}
