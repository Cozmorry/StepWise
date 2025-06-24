// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ActivityRecordAdapter extends TypeAdapter<ActivityRecord> {
  @override
  final int typeId = 0;

  @override
  ActivityRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ActivityRecord(
      date: fields[0] as DateTime,
      steps: fields[1] as int,
      distance: fields[2] as double,
      calories: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, ActivityRecord obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.steps)
      ..writeByte(2)
      ..write(obj.distance)
      ..writeByte(3)
      ..write(obj.calories);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
