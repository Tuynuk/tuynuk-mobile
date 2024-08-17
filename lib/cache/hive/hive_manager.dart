import 'dart:convert';
import 'dart:typed_data';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:safe_file_sender/cache/hive/adapters/download_file_adapter.dart';

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
    Hive.box<DownloadFile>(downloads).put(fileId,
        DownloadFile(filePath, fileId, hmac, secretKey, base64Encode(salt)));
  }

  static Future<List<DownloadFile>> getFiles() async {
    return Hive.box<DownloadFile>(downloads).values.toList();
  }

  static Future<void> removeDownloadFile(String fileId) async {
    await Hive.box(downloads).delete(fileId);
  }
}
