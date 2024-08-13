import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:pointycastle/export.dart' as pc;

class FileEncryptionService {
  final String pin;

  FileEncryptionService(this.pin);

  Uint8List _generateSalt() {
    final secureRandom = pc.SecureRandom('AES/CTR/PRNG');
    secureRandom
        .seed(pc.KeyParameter(Uint8List.fromList(List.generate(32, (i) => i))));
    return secureRandom.nextBytes(16);
  }

  Uint8List _deriveKey(Uint8List salt) {
    final mac = pc.HMac(pc.SHA256Digest(), 64); // MAC for PBKDF2
    final pbkdf2 = pc.PBKDF2KeyDerivator(mac)
      ..init(pc.Pbkdf2Parameters(salt, 100000, 32));
    return pbkdf2.process(utf8.encode(pin));
  }

  Future<void> encryptFile(String filePath, String outputPath) async {
    final file = File(filePath);
    final fileData = await file.readAsBytes();

    final salt = _generateSalt();
    final key = _deriveKey(salt);
    print(salt);
    final encrypter =
        pc.PaddedBlockCipherImpl(pc.PKCS7Padding(), pc.AESEngine())
          ..init(
              true,
              pc.PaddedBlockCipherParameters(
                pc.KeyParameter(key),
                null,
              ));
    final iv = _generateSalt();
    final encrypted = encrypter.process(fileData);

    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(
      Uint8List.fromList(salt + iv + encrypted),
    );
  }

  Future<void> decryptFile(String encryptedFilePath, String outputPath) async {
    final encryptedFile = File(encryptedFilePath);
    final encryptedData = await encryptedFile.readAsBytes();

    final salt = encryptedData.sublist(0, 16);
    final iv = encryptedData.sublist(16, 32);
    final encryptedBytes = encryptedData.sublist(32);

    final key = _deriveKey(salt);
    final encrypter =
        pc.PaddedBlockCipherImpl(pc.PKCS7Padding(), pc.AESEngine())
          ..init(
              false,
              pc.PaddedBlockCipherParameters(
                pc.KeyParameter(key),
                null,
              ));
    final decrypted = encrypter.process(encryptedBytes);

    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(decrypted);
  }
}
