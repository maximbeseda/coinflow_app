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

  @HiveField(6)
  final double amount;

  @HiveField(7)
  final double? budget;

  @HiveField(8)
  final bool isArchived;

  Category({
    required this.id,
    required this.type,
    required this.name,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    this.amount = 0.0,
    this.budget,
    this.isArchived = false,
  });

  Category copyWith({
    String? name,
    IconData? icon,
    Color? bgColor,
    Color? iconColor,
    double? amount,
    double? budget,
    bool? isArchived,
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
    );
  }

  // toJson та fromJson залишаємо для міграції та бекапів
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
      amount: (json['amount'] ?? 0.0).toDouble(),
      budget: json['budget']?.toDouble(),
      isArchived: json['isArchived'] ?? false,
    );
  }
}
