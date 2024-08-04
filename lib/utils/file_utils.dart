import 'dart:io';

import 'package:safe_file_sender/dev/logger.dart';

class FileUtils {
  static String fileName(String path) =>
      path.split(Platform.pathSeparator).last;
}

extension FileExt on File {
  bool safeDelete() {
    try {
      delete();
      logMessage("File : $path deleted!");
      return true;
    } catch (e) {
      logMessage("Delete $path error");
      return false;
    }
  }
}
