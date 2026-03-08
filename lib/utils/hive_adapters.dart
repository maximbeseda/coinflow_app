import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class ColorAdapter extends TypeAdapter<Color> {
  @override
  final int typeId = 4; // Резервуємо унікальний ID

  @override
  Color read(BinaryReader reader) => Color(reader.readInt());

  @override
  void write(BinaryWriter writer, Color obj) => writer.writeInt(obj.toARGB32());
}

class IconDataAdapter extends TypeAdapter<IconData> {
  @override
  final int typeId = 5; // Резервуємо унікальний ID

  @override
  IconData read(BinaryReader reader) {
    return IconData(reader.readInt(), fontFamily: 'MaterialIcons');
  }

  @override
  void write(BinaryWriter writer, IconData obj) =>
      writer.writeInt(obj.codePoint);
}
