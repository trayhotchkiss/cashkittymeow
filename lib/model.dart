class Account {
  String title;
  double balance;
  List<Transaction> transactions;

  Account({
    required this.title,
    required this.balance,
    List<Transaction>? transactions,
  }) : transactions = transactions != null ? List.from(transactions) : [];
}

class Transaction {
  DateTime date;
  String description;
  double amount;

  Transaction(
      {required this.date, required this.description, required this.amount});
}
