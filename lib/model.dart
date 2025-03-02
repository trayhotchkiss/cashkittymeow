class Account {
  String title;
  double balance;
  List<Transaction> transactions;

  Account(
      {required this.title,
      required this.balance,
      this.transactions = const []});
}

class Transaction {
  DateTime date;
  String description;
  double amount;

  Transaction(
      {required this.date, required this.description, required this.amount});
}
