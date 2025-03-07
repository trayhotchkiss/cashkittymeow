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

  factory Account.fromJson(Map<String, dynamic> json) => Account(
        title: json['title'],
        balance: json['balance'],
        transactions: (json['transactions'] as List<dynamic>)
            .map((t) => Transaction.fromJson(t))
            .toList(),
      );
}

class Transaction {
  DateTime date;
  String description;
  double amount;

  Transaction({
    required this.date,
    required this.description,
    required this.amount,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'description': description,
        'amount': amount,
      };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        date: DateTime.parse(json['date']),
        description: json['description'],
        amount: json['amount'],
      );
}
