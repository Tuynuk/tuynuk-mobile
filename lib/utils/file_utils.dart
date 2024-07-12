import 'dart:io';

class FileUtils {
  static String fileName(String path) =>
      path.split(Platform.pathSeparator).last;
}
