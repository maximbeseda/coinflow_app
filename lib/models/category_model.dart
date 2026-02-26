import 'package:flutter/material.dart';

// ДОДАНО: Чіткі типи замість рядків "inc", "acc", "exp"
enum CategoryType { income, account, expense }

class Category {
  final String id;
  final CategoryType
  type; // ДОДАНО: Тепер тип - це окреме поле, а не просто частина ID
  String name;
  IconData icon;
  final Color bgColor;
  final Color iconColor;
  double amount;
  double? budget;

  Category({
    required this.id,
    required this.type, // Обов'язкове поле при створенні
    required this.name,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    this.amount = 0.0,
    this.budget,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type
        .name, // Зберігаємо тип як текст ("income", "account" або "expense")
    'name': name,
    'icon': icon.codePoint,
    'bgColor': bgColor.toARGB32(),
    'iconColor': iconColor.toARGB32(),
    'amount': amount,
    'budget': budget,
  };

  factory Category.fromJson(Map<String, dynamic> json) {
    // ЗВОРОТНА СУМІСНІСТЬ: Якщо в базі старий запис без поля 'type',
    // ми витягуємо його з 'id', щоб не втратити твої дані.
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
      bgColor: Color(json['bgColor']),
      iconColor: Color(json['iconColor']),
      amount: json['amount'].toDouble(),
      budget: json['budget']?.toDouble(),
    );
  }
}
