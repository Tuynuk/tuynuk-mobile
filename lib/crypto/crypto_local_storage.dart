import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:encrypt_shared_preferences/provider.dart';
import 'package:pointycastle/export.dart' as pc;
import 'package:safe_file_sender/crypto/crypto_core.dart';
import 'package:safe_file_sender/dev/logger.dart';

void _isolateEntryPoint(SendPort sendPort) {
  final receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);

  receivePort.listen((message) {
    final command = message[0] as String;
    final arguments = message.sublist(1);
    final responsePort = arguments.last as SendPort;

    try {
      if (command == 'encrypt') {
        final filePath = arguments[0] as String;
        final outputPath = arguments[1] as String;
        final pin = arguments[2] as String;

        final service = FileEncryptionService(pin);
        service.encryptFileSync(filePath, outputPath);
        responsePort.send('Encryption done');
      } else if (command == 'decrypt') {
        final encryptedFilePath = arguments[0] as String;
        final outputPath = arguments[1] as String;
        final pin = arguments[2] as String;

        final service = FileEncryptionService(pin);
        final decryptedData = service.decryptFileSync(encryptedFilePath, outputPath);
        responsePort.send(decryptedData);
      }
    } catch (e) {
      responsePort.send('Error: $e');
    }
  });
}
class FileEncryptionService {
  final String pin;

  FileEncryptionService(this.pin);

  Uint8List _generateSalt() {
    final secureRandom = pc.SecureRandom('AES/CTR/PRNG');
    secureRandom.seed(pc.KeyParameter(Uint8List.fromList(List.generate(32, (i) => i))));
    return secureRandom.nextBytes(16);
  }

  Uint8List _deriveKey(Uint8List salt) {
    final mac = pc.HMac(pc.SHA256Digest(), 64); // MAC for PBKDF2
    final pbkdf2 = pc.PBKDF2KeyDerivator(mac)
      ..init(pc.Pbkdf2Parameters(salt, 100000, 32));
    return pbkdf2.process(utf8.encode(pin));
  }

  void encryptFileSync(String filePath, String outputPath) {
    logMessage('Encryption file service');
    final file = File(filePath);
    final fileData = file.readAsBytesSync();

    final salt = _generateSalt();
    final key = _deriveKey(salt);
    final encrypter = pc.PaddedBlockCipherImpl(pc.PKCS7Padding(), pc.AESEngine())
      ..init(
          true,
          pc.PaddedBlockCipherParameters(
            pc.KeyParameter(key),
            null,
          ));
    final iv = _generateSalt();
    final encrypted = encrypter.process(fileData);

    final outputFile = File(outputPath);
    outputFile.writeAsBytesSync(
      Uint8List.fromList(salt + iv + encrypted),
    );
    logMessage('Encryption file service done');
  }

  Uint8List decryptFileSync(String encryptedFilePath, String outputPath) {
    logMessage('Decryption file service');
    final encryptedFile = File(encryptedFilePath);
    final encryptedData = encryptedFile.readAsBytesSync();

    final salt = encryptedData.sublist(0, 16);
    final iv = encryptedData.sublist(16, 32);
    final encryptedBytes = encryptedData.sublist(32);

    final key = _deriveKey(salt);
    final encrypter = pc.PaddedBlockCipherImpl(pc.PKCS7Padding(), pc.AESEngine())
      ..init(
          false,
          pc.PaddedBlockCipherParameters(
            pc.KeyParameter(key),
            null,
          ));
    final decrypted = encrypter.process(encryptedBytes);

    final outputFile = File(outputPath);
    outputFile.writeAsBytesSync(decrypted);
    logMessage('Decryption file service done');

    return decrypted;
  }

  Future<void> encryptFile(String filePath, String outputPath) async {
    final receivePort = ReceivePort();
    final isolate = await Isolate.spawn(_isolateEntryPoint, receivePort.sendPort);
    final sendPort = await receivePort.first as SendPort;

    final response = ReceivePort();
    sendPort.send([
      'encrypt',
      filePath,
      outputPath,
      pin,
      response.sendPort,
    ]);

    final result = await response.first;
    print(result);
    isolate.kill(priority: Isolate.immediate);
  }

  Future<Uint8List> decryptFile(String encryptedFilePath, String outputPath) async {
    final receivePort = ReceivePort();
    final isolate = await Isolate.spawn(_isolateEntryPoint, receivePort.sendPort);
    final sendPort = await receivePort.first as SendPort;

    final response = ReceivePort();
    sendPort.send([
      'decrypt',
      encryptedFilePath,
      outputPath,
      pin,
      response.sendPort,
    ]);

    final result = await response.first;
    isolate.kill(priority: Isolate.immediate);

    if (result is String && result.startsWith('Error:')) {
      throw Exception(result);
    }

    return result as Uint8List;
  }
}