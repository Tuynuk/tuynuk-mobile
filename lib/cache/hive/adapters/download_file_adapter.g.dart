// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'download_file_adapter.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DownloadFileAdapter extends TypeAdapter<DownloadFile> {
  @override
  final int typeId = 1;

  @override
  DownloadFile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DownloadFile(
      fields[2] as String,
      fields[0] as String,
      fields[1] as String,
      fields[3] as String,
      fields[4] as String,
      fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, DownloadFile obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.fileId)
      ..writeByte(1)
      ..write(obj.hmac)
      ..writeByte(2)
      ..write(obj.path)
      ..writeByte(3)
      ..write(obj.secretKey)
      ..writeByte(4)
      ..write(obj.salt)
      ..writeByte(5)
      ..write(obj.createDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DownloadFileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
