// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'check_history_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CheckHistoryModelAdapter extends TypeAdapter<CheckHistoryModel> {
  @override
  final int typeId = 2;

  @override
  CheckHistoryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CheckHistoryModel(
      checkId: fields[0] as String,
      inputText: fields[1] as String,
      verdict: fields[2] as String,
      confidence: fields[3] as double,
      scamType: fields[4] as String,
      checkedAt: fields[5] as DateTime,
      hasImage: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, CheckHistoryModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.checkId)
      ..writeByte(1)
      ..write(obj.inputText)
      ..writeByte(2)
      ..write(obj.verdict)
      ..writeByte(3)
      ..write(obj.confidence)
      ..writeByte(4)
      ..write(obj.scamType)
      ..writeByte(5)
      ..write(obj.checkedAt)
      ..writeByte(6)
      ..write(obj.hasImage);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckHistoryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
