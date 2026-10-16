// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 1;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      minimumProfitMargin: fields[0] as double,
      autoDiscountEnabled: fields[1] as bool,
      syncEnabled: fields[2] as bool,
      backupEnabled: fields[3] as bool,
      storeName: fields[4] as String?,
      ownerName: fields[5] as String?,
      pin: fields[6] as String?,
      lastBackupDate: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.minimumProfitMargin)
      ..writeByte(1)
      ..write(obj.autoDiscountEnabled)
      ..writeByte(2)
      ..write(obj.syncEnabled)
      ..writeByte(3)
      ..write(obj.backupEnabled)
      ..writeByte(4)
      ..write(obj.storeName)
      ..writeByte(5)
      ..write(obj.ownerName)
      ..writeByte(6)
      ..write(obj.pin)
      ..writeByte(7)
      ..write(obj.lastBackupDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
