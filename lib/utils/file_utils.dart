import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:safe_file_sender/dev/logger.dart';

class FileUtils {
  static String fileName(String path) =>
      path.split(Platform.pathSeparator).last;

  static String extractFileId(String path) {
    return fileName(path).split('@').first;
  }

  static Future<bool> clearDecryptedCache() async {
    return File('${(await getApplicationDocumentsDirectory()).path}/downloads/temp/')
            .safeDelete(recursive: true) &&
        File('${(await getApplicationCacheDirectory()).path}/share_plus/')
            .safeDelete(recursive: true);
  }

  static File? fromSharedFile(SharedMediaFile? file) {
    if (file == null) return null;
    return File(file.path);
  }

  static File? fromFileSystemEntity(FileSystemEntity? file) {
    if (file == null) return null;
    return File(file.path);
  }
}

extension FileExt on File {
  bool safeDelete({bool recursive = false}) {
    try {
      if (existsSync() || Directory(path).existsSync()) {
        delete(recursive: recursive);
        logMessage('Path : $path deleted!');
        return true;
      } else {
        logMessage('$path not exist');
      }
      return false;
    } catch (e) {
      logMessage('Delete $path error');
      return false;
    }
  }
}
