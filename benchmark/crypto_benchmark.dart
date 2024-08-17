import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:safe_file_sender/crypto/crypto_core.dart';

import 'models.dart';

final _file = File('${Directory.current.path}/files/input.exe');
final _outPath = File('${Directory.current.path}/files').path;
late Uint8List _testKey;

void main() {
  _testKey = base64Decode(
      AppCrypto.encodeECPublicKey(AppCrypto.generateECKeyPair().publicKey));
  _benchmarkDeriveKeyByInput();
  _benchmarkSharedKey();
  _benchmarkEncryption();
  _benchmarkEncryptionIsolate();
  _benchmarkHmacGeneration();
}

void _benchmarkDeriveKeyByInput() async {
  final benchmark = BenchmarkTimer('key derive by input');
  await benchmark.runAsync(() async {
    await AppCrypto.deriveKeyIsolate('abcd@#dx21');
  });
}

void _benchmarkEncryptionIsolate() async {
  final benchmark = BenchmarkTimer('file encryption isolate');
  final File file = File('$_outPath/benchmark_encrypted_isolate.exe');
  await benchmark.runAsync(() async {
    final result =
        await AppCrypto.encryptAESInIsolate(_file.readAsBytesSync(), _testKey);
    await file.writeAsBytes(result);
  });
  _benchmarkDecryptionIsolate(file);
}

void _benchmarkDecryptionIsolate(File path) {
  final benchmark = BenchmarkTimer('file decryption isolate');
  benchmark.runAsync(() async {
    await AppCrypto.encryptAESInIsolate(path.readAsBytesSync(), _testKey);
  });
}

void _benchmarkDecryption(File path) {
  final benchmark = BenchmarkTimer('file decryption');
  benchmark.run(() {
    AppCrypto.decryptAES(path.readAsBytesSync(), _testKey);
  });
}

void _benchmarkSharedKey() {
  final benchmark = BenchmarkTimer('share key derive');

  benchmark.run(() {
    final userA = AppCrypto.generateECKeyPair();
    final userB = AppCrypto.generateECKeyPair();
    AppCrypto.deriveSharedSecret(userA.privateKey, userB.publicKey);
  });
}

void _benchmarkHmacGeneration() {
  final benchmark = BenchmarkTimer('hmac generation');

  benchmark.run(() {
    AppCrypto.generateHMAC(_testKey, _file.readAsBytesSync());
  });
}

void _benchmarkEncryption() {
  final benchmark = BenchmarkTimer('file encryption');
  final File file = File('$_outPath/benchmark_encryption_default.exe');
  benchmark.run(() {
    final bytes = AppCrypto.encryptAES(_file.readAsBytesSync(), _testKey);
    file.writeAsBytesSync(bytes);
  });
  _benchmarkDecryption(file);
}
