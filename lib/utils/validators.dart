import 'dart:io';

int maxFileTransferSizeInMB = 100;

class Validators {
  static bool canHandleFile(File? file) {
    if (file == null) return false;
    double sizeInMb = file.lengthSync() / (1024 * 1024);
    return sizeInMb < maxFileTransferSizeInMB;
  }
}
