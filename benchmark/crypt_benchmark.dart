import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:safe_file_sender/benchmark/models.dart';
import 'package:safe_file_sender/crypto/crypto.dart';

final _file = File("${Directory.current.path}/files/input.exe");
late Uint8List _testKey;

void main() {
  _testKey = base64Decode(
      AppCrypto.encodeECPublicKey(AppCrypto.generateECKeyPair().publicKey));
  _benchmarkSharedKey();
  _benchmarkEncryption();
  _benchmarkHmacGeneration();
}

void _benchmarkSharedKey() {
  final benchmark = BenchmarkTimer("share key derive");

  benchmark.run(() {
    final userA = AppCrypto.generateECKeyPair();
    final userB = AppCrypto.generateECKeyPair();
    AppCrypto.deriveSharedSecret(userA.privateKey, userB.publicKey);
  });
}

void _benchmarkHmacGeneration() {
  final benchmark = BenchmarkTimer("hmac generation");

  benchmark.run(() {
    AppCrypto.generateHMAC(_testKey, _file.readAsBytesSync());
  });
}

void _benchmarkEncryption() {
  final benchmark = BenchmarkTimer("file encryption");
  benchmark.run(() {
    AppCrypto.encryptAES(_file.readAsBytesSync(), _testKey);
  });
}

