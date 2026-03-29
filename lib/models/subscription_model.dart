import 'package:hive/hive.dart';

part 'subscription_model.g.dart';

@HiveType(typeId: 2)
class Subscription extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  // 👇 ЗМІНЕНО: Тепер int (в копійках/центах)
  @HiveField(2)
  int amount;

  @HiveField(3)
  String categoryId;

  @HiveField(4)
  String accountId;

  @HiveField(5)
  DateTime nextPaymentDate;

  @HiveField(6)
  String periodicity;

  @HiveField(7)
  int? customIconCodePoint;

  @HiveField(8)
  bool isAutoPay;

  // ДОДАНО: Валюта підписки (за замовчуванням UAH для зворотної сумісності)
  @HiveField(9, defaultValue: 'UAH')
  final String currency;

  Subscription({
    required this.id,
    required this.name,
    required this.amount,
    required this.categoryId,
    required this.accountId,
    required this.nextPaymentDate,
    this.periodicity = 'monthly',
    this.customIconCodePoint,
    this.isAutoPay = false,
    this.currency = 'UAH', // Захист для існуючих підписок
  });

  Subscription copyWith({
    String? name,
    int? amount, // 👇 ЗМІНЕНО: Тепер int?
    String? categoryId,
    String? accountId,
    DateTime? nextPaymentDate,
    String? periodicity,
    int? customIconCodePoint,
    bool? isAutoPay,
    String? currency,
  }) {
    return Subscription(
      id: id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      nextPaymentDate: nextPaymentDate ?? this.nextPaymentDate,
      periodicity: periodicity ?? this.periodicity,
      customIconCodePoint: customIconCodePoint ?? this.customIconCodePoint,
      isAutoPay: isAutoPay ?? this.isAutoPay,
      currency: currency ?? this.currency,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'categoryId': categoryId,
      'accountId': accountId,
      'nextPaymentDate': nextPaymentDate.toIso8601String(),
      'periodicity': periodicity,
      'customIconCodePoint': customIconCodePoint,
      'isAutoPay': isAutoPay,
      'currency': currency,
    };
  }

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'],
      name: json['name'],
      amount: (json['amount'] as num).toInt(), // 👇 ЗМІНЕНО: на .toInt()
      categoryId: json['categoryId'],
      accountId: json['accountId'],
      nextPaymentDate: DateTime.parse(json['nextPaymentDate']),
      periodicity: json['periodicity'] ?? 'monthly',
      customIconCodePoint: json['customIconCodePoint'],
      isAutoPay: json['isAutoPay'] ?? false,
      currency: json['currency'] ?? 'UAH',
    );
  }
}
