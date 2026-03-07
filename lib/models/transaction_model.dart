class Transaction {
  final String id;
  final String fromId; // ID категорії, звідки пішли гроші (рахунок або дохід)
  final String toId; // ID категорії, куди прийшли гроші (витрата або рахунок)
  final String title; // Назва (напр. назва підписки або просто коментар)
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

  // ДОДАНО: Метод copyWith для легкого редагування (наприклад, при зміні суми або дати)
  Transaction copyWith({
    String? fromId,
    String? toId,
    String? title,
    double? amount,
    DateTime? date,
  }) {
    return Transaction(
      id: id, // ID ніколи не змінюється
      fromId: fromId ?? this.fromId,
      toId: toId ?? this.toId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
    );
  }

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
    // ФІКС: Безпечне приведення до double, якщо в JSON прийшло ціле число (int)
    amount: (json['amount'] as num).toDouble(),
    date: DateTime.parse(json['date']),
  );
}
