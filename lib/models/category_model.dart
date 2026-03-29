import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

// Цей рядок ОБОВ'ЯЗКОВИЙ.
part 'category_model.g.dart';

@HiveType(typeId: 3)
enum CategoryType {
  @HiveField(0)
  income,
  @HiveField(1)
  account,
  @HiveField(2)
  expense,
}

@HiveType(typeId: 0)
class Category extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final CategoryType type;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final IconData icon;

  @HiveField(4)
  final Color bgColor;

  @HiveField(5)
  final Color iconColor;

  // 👇 ЗМІНЕНО: Тепер int (в копійках)
  @HiveField(6)
  final int amount;

  // 👇 ЗМІНЕНО: Тепер int? (в копійках)
  @HiveField(7)
  final int? budget;

  @HiveField(8)
  final bool isArchived;

  // ДОДАНО: Валюта рахунку (за замовчуванням UAH для зворотної сумісності)
  @HiveField(9, defaultValue: 'UAH')
  final String currency;

  // ДОДАНО: Чи включати в загальний баланс (за замовчуванням true)
  @HiveField(10, defaultValue: true)
  final bool includeInTotal;

  Category({
    required this.id,
    required this.type,
    required this.name,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    this.amount = 0, // 👇 ЗМІНЕНО: 0 замість 0.0
    this.budget,
    this.isArchived = false,
    this.currency = 'UAH',
    this.includeInTotal = true,
  });

  Category copyWith({
    String? name,
    IconData? icon,
    Color? bgColor,
    Color? iconColor,
    int? amount, // 👇 ЗМІНЕНО
    int? budget, // 👇 ЗМІНЕНО
    bool? isArchived,
    String? currency,
    bool? includeInTotal,
  }) {
    return Category(
      id: id,
      type: type,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      bgColor: bgColor ?? this.bgColor,
      iconColor: iconColor ?? this.iconColor,
      amount: amount ?? this.amount,
      budget: budget ?? this.budget,
      isArchived: isArchived ?? this.isArchived,
      currency: currency ?? this.currency,
      includeInTotal: includeInTotal ?? this.includeInTotal,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'name': name,
    'icon': icon.codePoint,
    'bgColor': bgColor.toARGB32(),
    'iconColor': iconColor.toARGB32(),
    'amount': amount,
    'budget': budget,
    'isArchived': isArchived,
    'currency': currency,
    'includeInTotal': includeInTotal,
  };

  factory Category.fromJson(Map<String, dynamic> json) {
    CategoryType parsedType;
    if (json['type'] != null) {
      parsedType = CategoryType.values.byName(json['type']);
    } else {
      final idString = json['id'] as String;
      if (idString.startsWith('inc')) {
        parsedType = CategoryType.income;
      } else if (idString.startsWith('acc')) {
        parsedType = CategoryType.account;
      } else {
        parsedType = CategoryType.expense;
      }
    }

    return Category(
      id: json['id'],
      type: parsedType,
      name: json['name'],
      icon: IconData(json['icon'], fontFamily: 'MaterialIcons'),
      bgColor: Color(json['bgColor'] ?? 0xFFE0E0E0),
      iconColor: Color(json['iconColor'] ?? 0xFF000000),
      amount:
          (json['amount'] as num?)?.toInt() ??
          0, // 👇 ЗМІНЕНО на toInt() і дефолт 0
      budget: (json['budget'] as num?)?.toInt(), // 👇 ЗМІНЕНО на toInt()
      isArchived: json['isArchived'] ?? false,
      currency: json['currency'] ?? 'UAH',
      includeInTotal: json['includeInTotal'] ?? true,
    );
  }
}
