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
  String title;

  @HiveField(4)
  double amount;

  @HiveField(5)
  DateTime date;

  // ДОДАНО: Валюта, в якій відбулася транзакція (за замовчуванням UAH)
  @HiveField(6, defaultValue: 'UAH')
  final String currency;

  // ДОДАНО: Курс до БАЗОВОЇ валюти на дату транзакції (за замовчуванням 1.0)
  @HiveField(7, defaultValue: 1.0)
  final double exchangeRate;

  // ДОДАНО: Сума, яка реально зарахувалася на цільовий рахунок (для переказів між різними валютами)
  @HiveField(8)
  double? targetAmount;

  // ДОДАНО: Валюта цільового рахунку (для переказів між різними валютами)
  @HiveField(9)
  final String? targetCurrency;

  Transaction({
    required this.id,
    required this.fromId,
    required this.toId,
    required this.title,
    required this.amount,
    required this.date,
    this.currency = 'UAH',
    this.exchangeRate = 1.0,
    this.targetAmount,
    this.targetCurrency,
  });

  Transaction copyWith({
    String? fromId,
    String? toId,
    String? title,
    double? amount,
    DateTime? date,
    String? currency,
    double? exchangeRate,
    double? targetAmount,
    String? targetCurrency,
  }) {
    return Transaction(
      id: id,
      fromId: fromId ?? this.fromId,
      toId: toId ?? this.toId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      currency: currency ?? this.currency,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      targetAmount: targetAmount ?? this.targetAmount,
      targetCurrency: targetCurrency ?? this.targetCurrency,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fromId': fromId,
    'toId': toId,
    'title': title,
    'amount': amount,
    'date': date.toIso8601String(),
    'currency': currency, // ДОДАНО
    'exchangeRate': exchangeRate, // ДОДАНО
    'targetAmount': targetAmount, // ДОДАНО
    'targetCurrency': targetCurrency, // ДОДАНО
  };

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      fromId: json['fromId'],
      toId: json['toId'],
      title: json['title'],
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date']),
      currency: json['currency'] ?? 'UAH', // Міграція
      exchangeRate:
          (json['exchangeRate'] as num?)?.toDouble() ?? 1.0, // Міграція
      targetAmount: (json['targetAmount'] as num?)?.toDouble(),
      targetCurrency: json['targetCurrency'],
    );
  }
}
