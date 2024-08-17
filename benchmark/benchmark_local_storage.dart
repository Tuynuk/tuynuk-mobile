import 'dart:io';

import 'package:safe_file_sender/crypto/crypto_local_storage.dart';

void main() async {
  final file = FileEncryptionService('123456');
  final encryptedOutPath =
      '${Directory.current.path}/files/output_file_encryption_service.enc';
  await file.encryptFile(
      '${Directory.current.path}/files/input.exe', encryptedOutPath);
  await file.decryptFile(encryptedOutPath,
      '${Directory.current.path}/files/output_file_encryption_service_decrypted.exe');
}
