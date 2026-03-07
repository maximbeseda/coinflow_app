import 'package:flutter/material.dart';

enum CategoryType { income, account, expense }

class Category {
  final String id;
  final CategoryType type;
  final String name;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final double amount;
  final double? budget;
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
