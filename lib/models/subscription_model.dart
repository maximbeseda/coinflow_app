import 'package:hive/hive.dart';

part 'subscription_model.g.dart';

@HiveType(typeId: 2)
class Subscription extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double amount;

  @HiveField(3)
  String categoryId;

  @HiveField(4)
  String accountId;

  @HiveField(5)
  DateTime nextPaymentDate;

  @HiveField(6)
  String periodicity;

  // ДОДАНО: Поле для збереження власної іконки (може бути пустим, тоді беремо з категорії)
  @HiveField(7)
  int? customIconCodePoint;

  // ДОДАНО: Поле автосписання
  @HiveField(8)
  bool isAutoPay;

  Subscription({
    required this.id,
    required this.name,
    required this.amount,
    required this.categoryId,
    required this.accountId,
    required this.nextPaymentDate,
    this.periodicity = 'monthly',
    this.customIconCodePoint, // ДОДАНО
    this.isAutoPay = false, // За замовчуванням вимкнено
  });

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
    };
  }

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'],
      name: json['name'],
      amount: json['amount'],
      categoryId: json['categoryId'],
      accountId: json['accountId'],
      nextPaymentDate: DateTime.parse(json['nextPaymentDate']),
      periodicity: json['periodicity'] ?? 'monthly',
      customIconCodePoint: json['customIconCodePoint'],
      isAutoPay: json['isAutoPay'] ?? false,
    );
  }
}
