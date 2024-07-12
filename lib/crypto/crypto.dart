import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:pointycastle/export.dart';

class AppCrypto {
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

  static Future<Uint8List> decryptAESInIsolate(
      Uint8List bytes, Uint8List sharedKey) async {
    final receivePort = ReceivePort();
    final isolate = await Isolate.spawn(
      _isolateEntry,
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
}

void _encryptIsolateEntry(_IsolateData data) {
  final encryptedBytes = AppCrypto.encryptAES(data.bytes, data.sharedKey);
  data.sendPort.send(encryptedBytes);
}

void _isolateEntry(_IsolateData data) {
  final decryptedBytes = AppCrypto.decryptAES(data.bytes, data.sharedKey);
  data.sendPort.send(decryptedBytes);
}

class _IsolateData {
  final Uint8List bytes;
  final Uint8List sharedKey;
  final SendPort sendPort;

  _IsolateData(this.bytes, this.sharedKey, this.sendPort);
}
