import 'package:hive/hive.dart';

part 'download_file_adapter.g.dart';

@HiveType(typeId: 1)
class DownloadFile extends HiveObject {
  @HiveField(0)
  final String fileId;
  @HiveField(1)
  final String hmac;
  @HiveField(2)
  final String path;
  @HiveField(3)
  final String secretKey;
  @HiveField(4)
  final String salt;
  @HiveField(5)
  final String createDate;

  DownloadFile(this.path, this.fileId, this.hmac, this.secretKey, this.salt, this.createDate);
}
