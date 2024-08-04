import 'dart:io';

class FileUtils {
  static String fileName(String path) =>
      path.split(Platform.pathSeparator).last;
}

extension FileExt on File {
  bool safeDelete() {
    try {
      delete();
      return true;
    } catch (e) {
      return false;
    }
  }
}
