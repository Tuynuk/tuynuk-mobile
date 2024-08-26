import 'dart:convert';
import 'dart:typed_data';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:safe_file_sender/cache/hive/adapters/download_file_adapter.dart';
import 'package:safe_file_sender/dev/logger.dart';

class HiveManager {
  HiveManager._();

  static String downloads = 'downloads';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(DownloadFileAdapter());
  }

  static Future<void> openDownloadsBox(Uint8List key) async {
    if (!Hive.isBoxOpen(downloads)) {
      await Hive.openBox<DownloadFile>(downloads,
          encryptionCipher: HiveAesCipher(key.reversed.toList()));
    }
  }

  static Future<void> closeDownloadsBox(Uint8List key) async {
    if (Hive.isBoxOpen(downloads)) {
      Hive.box(downloads).close();
    }
  }

  static Future<void> saveFile(String fileId, String filePath, String hmac,
      String secretKey, Uint8List salt) async {
    Hive.box<DownloadFile>(downloads).put(
        fileId,
        DownloadFile(filePath, fileId, hmac, secretKey, base64Encode(salt),
            DateTime.now().toIso8601String()));
  }

  static Future<List<DownloadFile>> getFiles() async {
    final values = Hive.box<DownloadFile>(downloads).values.toList();
    values.sort((b,a) => a.createDate.compareTo(b.createDate));
    return values;
  }

  static Future<void> removeDownloadFile(String fileId) async {
    if (Hive.isBoxOpen(downloads)) {
      await Hive.box<DownloadFile>(downloads).delete(fileId);
    }
  }
}
