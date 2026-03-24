import 'package:hive/hive.dart';

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

  @HiveField(6, defaultValue: 'UAH')
  final String currency;

  @HiveField(7, defaultValue: 1.0)
  double exchangeRate;

  @HiveField(8)
  double? targetAmount;

  @HiveField(9)
  final String? targetCurrency;

  // 👇 ДОДАНО: Валюта, відносно якої був збережений exchangeRate (захист від зміни базової валюти)
  @HiveField(10)
  String? rateBaseCurrency;

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
    this.rateBaseCurrency, // ДОДАНО
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
    String? rateBaseCurrency, // ДОДАНО
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
      rateBaseCurrency: rateBaseCurrency ?? this.rateBaseCurrency, // ДОДАНО
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fromId': fromId,
    'toId': toId,
    'title': title,
    'amount': amount,
    'date': date.toIso8601String(),
    'currency': currency,
    'exchangeRate': exchangeRate,
    'targetAmount': targetAmount,
    'targetCurrency': targetCurrency,
    'rateBaseCurrency': rateBaseCurrency, // ДОДАНО
  };

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      fromId: json['fromId'],
      toId: json['toId'],
      title: json['title'],
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date']),
      currency: json['currency'] ?? 'UAH',
      exchangeRate: (json['exchangeRate'] as num?)?.toDouble() ?? 1.0,
      targetAmount: (json['targetAmount'] as num?)?.toDouble(),
      targetCurrency: json['targetCurrency'],
      rateBaseCurrency: json['rateBaseCurrency'], // ДОДАНО
    );
  }
}
