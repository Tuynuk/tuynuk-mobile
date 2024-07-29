import 'dart:io';

import 'package:convert/convert.dart';
import 'package:safe_file_sender/crypto/crypto.dart';

void main() {
  final start = DateTime.now().millisecondsSinceEpoch;
  final userA = AppCrypto.generateECKeyPair();
  final userB = AppCrypto.generateECKeyPair();
  final sharedKey =
      AppCrypto.deriveSharedSecret(userA.privateKey, userB.publicKey);

  final file = File("${Directory.current.path}/files/input.exe");
  final endDeriveSharedKey = DateTime.now().millisecondsSinceEpoch;
  print("Benchmark derive shared key: ${(endDeriveSharedKey - start)}ms");
  final hmac = AppCrypto.generateHMAC(sharedKey, file.readAsBytesSync());
  print("HMAC ${hex.encode(hmac)}");
  final end = DateTime.now().millisecondsSinceEpoch;
  print("Benchmark generate HMAC: ${(end - start)}ms");

  ///Benchmark encryption
  final startEnc = DateTime.now().millisecondsSinceEpoch;
  AppCrypto.encryptAES(file.readAsBytesSync(), sharedKey);
  final endEnc = DateTime.now().millisecondsSinceEpoch;

  print("Benchmark encryption: ${(endEnc - startEnc)}ms");
}
