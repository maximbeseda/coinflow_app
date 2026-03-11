// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TransactionAdapter extends TypeAdapter<Transaction> {
  @override
  final int typeId = 1;

  @override
  Transaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Transaction(
      id: fields[0] as String,
      fromId: fields[1] as String,
      toId: fields[2] as String,
      title: fields[3] as String,
      amount: fields[4] as double,
      date: fields[5] as DateTime,
      currency: fields[6] == null ? 'UAH' : fields[6] as String,
      exchangeRate: fields[7] == null ? 1.0 : fields[7] as double,
      targetAmount: fields[8] as double?,
      targetCurrency: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Transaction obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.fromId)
      ..writeByte(2)
      ..write(obj.toId)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.amount)
      ..writeByte(5)
      ..write(obj.date)
      ..writeByte(6)
      ..write(obj.currency)
      ..writeByte(7)
      ..write(obj.exchangeRate)
      ..writeByte(8)
      ..write(obj.targetAmount)
      ..writeByte(9)
      ..write(obj.targetCurrency);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
