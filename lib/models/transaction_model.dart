import 'package:hive/hive.dart';

// Цей рядок ОБОВ'ЯЗКОВИЙ. Назва має точно збігатися з назвою цього файлу + .g.dart
part 'transaction_model.g.dart';

@HiveType(typeId: 1)
class Transaction extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String fromId;

  @HiveField(2)
  final String toId;

  @HiveField(3)
  final String title;

  @HiveField(4)
  double amount;

  @HiveField(5)
  DateTime date;

  Transaction({
    required this.id,
    required this.fromId,
    required this.toId,
    required this.title,
    required this.amount,
    required this.date,
  });

  Transaction copyWith({
    String? fromId,
    String? toId,
    String? title,
    double? amount,
    DateTime? date,
  }) {
    return Transaction(
      id: id,
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

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      fromId: json['fromId'],
      toId: json['toId'],
      title: json['title'],
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date']),
    );
  }
}
