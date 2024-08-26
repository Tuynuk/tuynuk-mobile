import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:pointycastle/export.dart';
import 'package:safe_file_sender/crypto/crypto_local_storage.dart';

class AppCrypto {
  AppCrypto._();

  static FileEncryptionService fileEncryptionService(String pin) =>
      FileEncryptionService(pin);

  static Uint8List generateSaltPRNG() {
    final secureRandom = SecureRandom('AES/CTR/PRNG');
    secureRandom
        .seed(KeyParameter(Uint8List.fromList(List.generate(32, (i) => i))));
    return secureRandom.nextBytes(16);
  }

  static Uint8List deriveKey(String input) {
    final mac = HMac(SHA256Digest(), 64);
    final pbkdf2 = PBKDF2KeyDerivator(mac)
      ..init(Pbkdf2Parameters(generateSaltPRNG(), 100000, 32));
    return pbkdf2.process(utf8.encode(input));
  }

  static Future<Uint8List> deriveKeyIsolate(String input) async {
    final receivePort = ReceivePort();
    final isolate = await Isolate.spawn(
      _deriveKeyByValueEntry,
      _IsolateSingleStringData(input, receivePort.sendPort),
    );

    final result = await receivePort.first as Uint8List;
    isolate.kill(priority: Isolate.immediate);
    return result;
  }

  static Uint8List _generateRandomBytes(int length) {
    final random = Random.secure();
    var values = List<int>.generate(length, (index) => random.nextInt(256));
    return Uint8List.fromList(values);
  }

  static Future<Uint8List> encryptAESInIsolate(
      Uint8List plaintext, Uint8List key) async {
    final receivePort = ReceivePort();
    final isolate = await Isolate.spawn(
      _encryptIsolateEntry,
      _IsolateData(plaintext, key, receivePort.sendPort),
    );

    final result = await receivePort.first as Uint8List;
    isolate.kill(priority: Isolate.immediate);
    return result;
  }

  static Uint8List encryptAES(Uint8List plaintext, Uint8List key) {
    final iv = _generateRandomBytes(16);

    final cipher = PaddedBlockCipherImpl(
      PKCS7Padding(),
      CBCBlockCipher(AESEngine()),
    )..init(
        true,
        PaddedBlockCipherParameters(
          ParametersWithIV<KeyParameter>(
              KeyParameter(Uint8List.fromList(key.sublist(0, 32))), iv),
          null,
        ),
      );

    final encrypted = cipher.process(plaintext);

    return Uint8List.fromList(iv + encrypted);
  }

  static Future<void> decryptFileAES(
      String inputPath, String outputPath, Uint8List key) async {
    final inputFile = File(inputPath);
    final outputFile = File(outputPath);
    final inputStream = inputFile.openRead();
    final outputSink = outputFile.openWrite();

    final iv = await inputStream.first;

    final cipher = PaddedBlockCipherImpl(
      PKCS7Padding(),
      CBCBlockCipher(AESEngine()),
    )..init(
        false,
        PaddedBlockCipherParameters(
          ParametersWithIV<KeyParameter>(
              KeyParameter(Uint8List.fromList(key.sublist(0, 32))),
              Uint8List.fromList(iv)),
          null,
        ),
      );

    await for (final chunk in inputStream) {
      final decryptedChunk = cipher.process(Uint8List.fromList(chunk));
      outputSink.add(decryptedChunk);
    }

    await outputSink.close();
  }

  static Future<void> encryptFileAES(
      String inputPath, String outputPath, Uint8List key) async {
    final iv = _generateRandomBytes(16);

    final cipher = PaddedBlockCipherImpl(
      PKCS7Padding(),
      CBCBlockCipher(AESEngine()),
    )..init(
        true,
        PaddedBlockCipherParameters(
          ParametersWithIV<KeyParameter>(
              KeyParameter(Uint8List.fromList(key.sublist(0, 32))), iv),
          null,
        ),
      );

    final inputFile = File(inputPath);
    final outputFile = File(outputPath);
    final outputSink = outputFile.openWrite();

    outputSink.add(iv);

    final inputStream = inputFile.openRead();
    await for (final chunk in inputStream) {
      final encryptedChunk = cipher.process(Uint8List.fromList(chunk));
      outputSink.add(encryptedChunk);
    }

    await outputSink.close();
  }

  static Future<Uint8List> generateHMACIsolate(
      Uint8List key, Uint8List message) async {
    final receivePort = ReceivePort();
    final isolate = await Isolate.spawn(
      _generateHMACIsolateEntry,
      _IsolateData(message, key, receivePort.sendPort),
    );

    final result = await receivePort.first as Uint8List;
    isolate.kill(priority: Isolate.immediate);
    return result;
  }

  static Future<Uint8List> decryptAESInIsolate(
      Uint8List bytes, Uint8List sharedKey) async {
    final receivePort = ReceivePort();
    final isolate = await Isolate.spawn(
      _decryptIsolateEntry,
      _IsolateData(bytes, sharedKey, receivePort.sendPort),
    );

    final result = await receivePort.first as Uint8List;
    isolate.kill(priority: Isolate.immediate);
    return result;
  }

  static Uint8List decryptAES(Uint8List ciphertext, Uint8List key) {
    final iv = ciphertext.sublist(0, 16);
    final encrypted = ciphertext.sublist(16);

    final cipher = PaddedBlockCipherImpl(
      PKCS7Padding(),
      CBCBlockCipher(AESEngine()),
    )..init(
        false,
        PaddedBlockCipherParameters(
          ParametersWithIV<KeyParameter>(KeyParameter(key.sublist(0, 32)), iv),
          null,
        ),
      );

    final decrypted = cipher.process(encrypted);

    return decrypted;
  }

  static AsymmetricKeyPair<ECPublicKey, ECPrivateKey> generateECKeyPair(
      {int bitLength = 2048}) {
    final keyGen = ECKeyGenerator()
      ..init(ParametersWithRandom(
          ECKeyGeneratorParameters(ECCurve_secp256r1()), _secureRandom()));
    final pair = keyGen.generateKeyPair();
    final public = pair.publicKey as ECPublicKey;
    final private = pair.privateKey as ECPrivateKey;

    return AsymmetricKeyPair<ECPublicKey, ECPrivateKey>(public, private);
  }

  static SecureRandom _secureRandom() {
    final secureRandom = FortunaRandom();
    final random = Random.secure();
    final seeds = <int>[];
    for (int i = 0; i < 32; i++) {
      seeds.add(random.nextInt(256));
    }
    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));
    return secureRandom;
  }

  static Uint8List deriveSharedSecret(
      ECPrivateKey privateKey, ECPublicKey serverPublicKey) {
    final ecdh = ECDHBasicAgreement();
    ecdh.init(privateKey);
    final sharedSecret = ecdh.calculateAgreement(serverPublicKey);
    final sharedSecretBytes = Uint8List.fromList(
        sharedSecret.toRadixString(16).padLeft(64, '0').codeUnits);
    return sharedSecretBytes;
  }

  static String encodeECPublicKey(ECPublicKey publicKey) {
    final Q = publicKey.Q!;
    final x = Q.x!.toBigInteger()!;
    final y = Q.y!.toBigInteger()!;
    final xBytes = _bigIntToByteArray(x);
    final yBytes = _bigIntToByteArray(y);

    const keySize = 32;
    final xPadded = Uint8List(keySize)..setAll(keySize - xBytes.length, xBytes);
    final yPadded = Uint8List(keySize)..setAll(keySize - yBytes.length, yBytes);

    final byteData = BytesBuilder()
      ..addByte(0x04)
      ..add(xPadded)
      ..add(yPadded);

    return base64Encode(byteData.toBytes());
  }

  static ECPublicKey decodeECPublicKey(String base64String) {
    final bytes = base64Decode(base64String);
    if (bytes[0] != 0x04) {
      throw ArgumentError('Invalid point encoding');
    }
    final keySize = (bytes.length - 1) ~/ 2;
    final xBytes = bytes.sublist(1, 1 + keySize);
    final yBytes = bytes.sublist(1 + keySize);

    final curve = ECCurve_secp256r1();
    final point = curve.curve.createPoint(
      BigInt.parse(hex.encode(xBytes), radix: 16),
      BigInt.parse(hex.encode(yBytes), radix: 16),
    );

    return ECPublicKey(point, curve);
  }

  static Uint8List _bigIntToByteArray(BigInt bigInt) {
    String hexString = bigInt.toRadixString(16);

    if (hexString.length % 2 != 0) {
      hexString = '0$hexString';
    }

    List<int> byteList = [];
    for (int i = 0; i < hexString.length; i += 2) {
      String byteString = hexString.substring(i, i + 2);
      int byteValue = int.parse(byteString, radix: 16);
      byteList.add(byteValue);
    }

    return Uint8List.fromList(byteList);
  }

  static Uint8List sha256Digest(Uint8List input, {List? salt}) {
    final Digest sha256 = SHA256Digest();
    final saltedInput = List<int>.from(input);
    if (salt != null) {
      saltedInput.addAll(Iterable.castFrom(salt));
    }
    return sha256.process(Uint8List.fromList(saltedInput));
  }

  static Uint8List generateHMAC(Uint8List key, Uint8List message) {
    var hmacSha256 = HMac(SHA256Digest(), 64);
    hmacSha256.init(KeyParameter(key));

    return hmacSha256.process(message);
  }

  static Uint8List hashWithSalt(Uint8List data, Uint8List salt) {
    final digest = Digest('SHA-256');

    final saltedData = Uint8List.fromList(data + salt);
    return digest.process(saltedData);
  }

  static Uint8List generateSalt({int length = 16}) {
    final secureRandom = _secureRandom();
    final salt = secureRandom.nextBytes(length);
    return salt;
  }

  static bool verifyHash(
      Uint8List input, Uint8List storedHash, Uint8List salt) {
    final hashedInput = hashWithSalt(input, salt);

    return _areUint8ListsEqual(hashedInput, storedHash);
  }

  static bool _areUint8ListsEqual(Uint8List list1, Uint8List list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }
}

void _encryptIsolateEntry(_IsolateData data) {
  final encryptedBytes = AppCrypto.encryptAES(data.bytes, data.sharedKey);
  data.sendPort.send(encryptedBytes);
}

void _deriveKeyByValueEntry(_IsolateSingleStringData data) {
  final encryptedBytes = AppCrypto.deriveKey(data.data);
  data.sendPort.send(encryptedBytes);
}

void _generateHMACIsolateEntry(_IsolateData data) {
  final encryptedBytes = AppCrypto.generateHMAC(data.bytes, data.sharedKey);
  data.sendPort.send(encryptedBytes);
}

void _decryptIsolateEntry(_IsolateData data) {
  try {
    final decryptedBytes = AppCrypto.decryptAES(data.bytes, data.sharedKey);
    data.sendPort.send(decryptedBytes);
  } catch (e) {
    data.sendPort.send([]);
  }
}

class _IsolateData {
  final Uint8List bytes;
  final Uint8List sharedKey;
  final SendPort sendPort;

  _IsolateData(this.bytes, this.sharedKey, this.sendPort);
}

class _IsolateSingleStringData {
  final String data;
  final SendPort sendPort;

  _IsolateSingleStringData(this.data, this.sendPort);
}
