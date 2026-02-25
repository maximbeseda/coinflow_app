import 'package:flutter/material.dart';

class Category {
  final String id;
  String name;
  IconData icon;
  final Color bgColor;
  final Color iconColor;
  double amount;
  double? budget; // (null означає, що бюджет не встановлено)

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    this.amount = 0.0,
    this.budget,
  });

  // Перетворюємо об'єкт у Map (для збереження)
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon': icon.codePoint, // Зберігаємо код іконки
    // ignore: deprecated_member_use
    'bgColor': bgColor.value, // Зберігаємо числовий код кольору
    // ignore: deprecated_member_use
    'iconColor': iconColor.value,
    'amount': amount,
    'budget': budget, // Зберігаємо бюджет
  };

  // Створюємо об'єкт із Map (для завантаження)
  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'],
    name: json['name'],
    icon: IconData(json['icon'], fontFamily: 'MaterialIcons'),
    bgColor: Color(json['bgColor']),
    iconColor: Color(json['iconColor']),
    amount: json['amount'].toDouble(),
    budget: json['budget']?.toDouble(), // Завантажуємо бюджет
  );
}
