//Клас для запису кожної операції.

class Transaction {
  final String id;
  final String fromId;
  final String toId;
  final String title;
  double amount;
  DateTime date;

  Transaction({
    required this.id,
    required this.fromId,
    required this.toId,
    required this.title,
    required this.amount,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'fromId': fromId,
    'toId': toId,
    'title': title,
    'amount': amount,
    'date': date.toIso8601String(),
  };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    id: json['id'],
    fromId: json['fromId'],
    toId: json['toId'],
    title: json['title'],
    amount: json['amount'].toDouble(),
    date: DateTime.parse(json['date']),
  );
}
