import 'package:flutter/material.dart';
import '../models/category_model.dart';

class CategoryDefaults {
  static const Color incomeBg = Colors.black;
  static const Color accountBg = Color(0xFF1E3A5F);
  static const Color expenseBg = Color(0xFFE0DFE8);

  static Color getBgColor(CategoryType type) {
    switch (type) {
      case CategoryType.income:
        return incomeBg;
      case CategoryType.account:
        return accountBg;
      case CategoryType.expense:
        return expenseBg;
    }
  }

  static Color getIconColor(CategoryType type) {
    return type == CategoryType.expense ? Colors.black : Colors.white;
  }
}
