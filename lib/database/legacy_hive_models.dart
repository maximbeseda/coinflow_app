import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

// ==========================================
// 1. Адаптери для специфічних типів (Кольори та Іконки)
// ==========================================
class LegacyColorAdapter extends TypeAdapter<Color> {
  @override
  final int typeId = 4;
  @override
  Color read(BinaryReader reader) => Color(reader.readInt());
  @override
  void write(BinaryWriter writer, Color obj) => writer.writeInt(obj.toARGB32());
}

class LegacyIconDataAdapter extends TypeAdapter<IconData> {
  @override
  final int typeId = 5;
  @override
  IconData read(BinaryReader reader) =>
      IconData(reader.readInt(), fontFamily: 'MaterialIcons');
  @override
  void write(BinaryWriter writer, IconData obj) =>
      writer.writeInt(obj.codePoint);
}

// ==========================================
// 2. Стара модель Категорій
// ==========================================
enum HiveCategoryType { income, account, expense }

class LegacyCategoryTypeAdapter extends TypeAdapter<HiveCategoryType> {
  @override
  final int typeId = 3;
  @override
  HiveCategoryType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return HiveCategoryType.income;
      case 1:
        return HiveCategoryType.account;
      case 2:
        return HiveCategoryType.expense;
      default:
        return HiveCategoryType.income;
    }
  }

  @override
  void write(BinaryWriter writer, HiveCategoryType obj) =>
      writer.writeByte(obj.index);
}

class HiveCategory {
  final String id;
  final HiveCategoryType type;
  final String name;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final int amount;
  final int? budget;
  final bool isArchived;
  final String currency;
  final bool includeInTotal;

  HiveCategory({
    required this.id,
    required this.type,
    required this.name,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    required this.amount,
    this.budget,
    required this.isArchived,
    required this.currency,
    required this.includeInTotal,
  });
}

class LegacyCategoryAdapter extends TypeAdapter<HiveCategory> {
  @override
  final int typeId = 0;
  @override
  HiveCategory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveCategory(
      id: fields[0] as String,
      type: fields[1] as HiveCategoryType,
      name: fields[2] as String,
      icon: fields[3] as IconData,
      bgColor: fields[4] as Color,
      iconColor: fields[5] as Color,
      amount: fields[6] as int,
      budget: fields[7] as int?,
      isArchived: fields[8] as bool,
      currency: fields[9] == null ? 'UAH' : fields[9] as String,
      includeInTotal: fields[10] == null ? true : fields[10] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, HiveCategory obj) {} // Писати в Hive ми більше не будемо
}

// ==========================================
// 3. Стара модель Транзакцій
// ==========================================
class HiveTransaction {
  final String id;
  final String fromId;
  final String toId;
  final String title;
  final DateTime date;
  final int amount;
  final String currency;
  final int? targetAmount;
  final String? targetCurrency;
  final int baseAmount;
  final String baseCurrency;

  HiveTransaction({
    required this.id,
    required this.fromId,
    required this.toId,
    required this.title,
    required this.date,
    required this.amount,
    required this.currency,
    this.targetAmount,
    this.targetCurrency,
    required this.baseAmount,
    required this.baseCurrency,
  });
}

class LegacyTransactionAdapter extends TypeAdapter<HiveTransaction> {
  @override
  final int typeId = 1;
  @override
  HiveTransaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveTransaction(
      id: fields[0] as String,
      fromId: fields[1] as String,
      toId: fields[2] as String,
      title: fields[3] as String,
      date: fields[4] as DateTime,
      amount: fields[5] as int,
      currency: fields[6] as String,
      targetAmount: fields[7] as int?,
      targetCurrency: fields[8] as String?,
      baseAmount: fields[9] == null ? 0 : fields[9] as int,
      baseCurrency: fields[10] as String,
    );
  }

  @override
  void write(BinaryWriter writer, HiveTransaction obj) {}
}

// ==========================================
// 4. Стара модель Підписок
// ==========================================
class HiveSubscription {
  final String id;
  final String name;
  final int amount;
  final String categoryId;
  final String accountId;
  final DateTime nextPaymentDate;
  final String periodicity;
  final int? customIconCodePoint;
  final bool isAutoPay;
  final String currency;

  HiveSubscription({
    required this.id,
    required this.name,
    required this.amount,
    required this.categoryId,
    required this.accountId,
    required this.nextPaymentDate,
    required this.periodicity,
    this.customIconCodePoint,
    required this.isAutoPay,
    required this.currency,
  });
}

class LegacySubscriptionAdapter extends TypeAdapter<HiveSubscription> {
  @override
  final int typeId = 2;
  @override
  HiveSubscription read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveSubscription(
      id: fields[0] as String,
      name: fields[1] as String,
      amount: fields[2] as int,
      categoryId: fields[3] as String,
      accountId: fields[4] as String,
      nextPaymentDate: fields[5] as DateTime,
      periodicity: fields[6] as String,
      customIconCodePoint: fields[7] as int?,
      isAutoPay: fields[8] as bool,
      currency: fields[9] == null ? 'UAH' : fields[9] as String,
    );
  }

  @override
  void write(BinaryWriter writer, HiveSubscription obj) {}
}
