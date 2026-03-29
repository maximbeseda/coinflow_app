// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CategoryAdapter extends TypeAdapter<Category> {
  @override
  final int typeId = 0;

  @override
  Category read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Category(
      id: fields[0] as String,
      type: fields[1] as CategoryType,
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
  void write(BinaryWriter writer, Category obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.icon)
      ..writeByte(4)
      ..write(obj.bgColor)
      ..writeByte(5)
      ..write(obj.iconColor)
      ..writeByte(6)
      ..write(obj.amount)
      ..writeByte(7)
      ..write(obj.budget)
      ..writeByte(8)
      ..write(obj.isArchived)
      ..writeByte(9)
      ..write(obj.currency)
      ..writeByte(10)
      ..write(obj.includeInTotal);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CategoryTypeAdapter extends TypeAdapter<CategoryType> {
  @override
  final int typeId = 3;

  @override
  CategoryType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return CategoryType.income;
      case 1:
        return CategoryType.account;
      case 2:
        return CategoryType.expense;
      default:
        return CategoryType.income;
    }
  }

  @override
  void write(BinaryWriter writer, CategoryType obj) {
    switch (obj) {
      case CategoryType.income:
        writer.writeByte(0);
        break;
      case CategoryType.account:
        writer.writeByte(1);
        break;
      case CategoryType.expense:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
