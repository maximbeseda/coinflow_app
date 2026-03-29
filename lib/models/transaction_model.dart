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
  DateTime date;

  // --- 1. SOURCE (Списання) ---
  @HiveField(5)
  double amount;

  @HiveField(6)
  final String currency;

  // --- 2. TARGET (Зарахування) ---
  @HiveField(7)
  double? targetAmount;

  @HiveField(8)
  final String? targetCurrency;

  // --- 3. BASE (Еквівалент для статистики) ---
  @HiveField(9, defaultValue: 0.0)
  double baseAmount;

  @HiveField(10)
  String baseCurrency;

  Transaction({
    required this.id,
    required this.fromId,
    required this.toId,
    required this.title,
    required this.date,
    // Source
    required this.amount,
    required this.currency,
    // Target
    this.targetAmount,
    this.targetCurrency,
    // Base
    required this.baseAmount,
    required this.baseCurrency,
  });

  Transaction copyWith({
    String? fromId,
    String? toId,
    String? title,
    DateTime? date,
    double? amount,
    String? currency,
    double? targetAmount,
    String? targetCurrency,
    double? baseAmount,
    String? baseCurrency,
  }) {
    return Transaction(
      id: id,
      fromId: fromId ?? this.fromId,
      toId: toId ?? this.toId,
      title: title ?? this.title,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      targetAmount: targetAmount ?? this.targetAmount,
      targetCurrency: targetCurrency ?? this.targetCurrency,
      baseAmount: baseAmount ?? this.baseAmount,
      baseCurrency: baseCurrency ?? this.baseCurrency,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fromId': fromId,
    'toId': toId,
    'title': title,
    'date': date.toIso8601String(),
    'amount': amount,
    'currency': currency,
    'targetAmount': targetAmount,
    'targetCurrency': targetCurrency,
    'baseAmount': baseAmount,
    'baseCurrency': baseCurrency,
  };

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      fromId: json['fromId'],
      toId: json['toId'],
      title: json['title'],
      date: DateTime.parse(json['date']),
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      targetAmount: (json['targetAmount'] as num?)?.toDouble(),
      targetCurrency: json['targetCurrency'],
      baseAmount: (json['baseAmount'] as num?)?.toDouble() ?? 0.0,
      baseCurrency: json['baseCurrency'] as String,
    );
  }
}
