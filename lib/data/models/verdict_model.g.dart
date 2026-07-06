// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verdict_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VerdictModelAdapter extends TypeAdapter<VerdictModel> {
  @override
  final int typeId = 0;

  @override
  VerdictModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VerdictModel(
      checkId: fields[0] as String,
      verdict: fields[1] as String,
      confidence: fields[2] as double,
      scamType: fields[3] as String,
      escalated: fields[4] as bool,
      why: (fields[5] as List).cast<String>(),
      whatToDo: (fields[6] as List).cast<String>(),
      trendNote: fields[7] as String?,
      language: fields[8] as String,
      disclaimer: fields[9] as String,
      inputText: fields[10] as String,
      checkedAt: fields[11] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, VerdictModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.checkId)
      ..writeByte(1)
      ..write(obj.verdict)
      ..writeByte(2)
      ..write(obj.confidence)
      ..writeByte(3)
      ..write(obj.scamType)
      ..writeByte(4)
      ..write(obj.escalated)
      ..writeByte(5)
      ..write(obj.why)
      ..writeByte(6)
      ..write(obj.whatToDo)
      ..writeByte(7)
      ..write(obj.trendNote)
      ..writeByte(8)
      ..write(obj.language)
      ..writeByte(9)
      ..write(obj.disclaimer)
      ..writeByte(10)
      ..write(obj.inputText)
      ..writeByte(11)
      ..write(obj.checkedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VerdictModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
