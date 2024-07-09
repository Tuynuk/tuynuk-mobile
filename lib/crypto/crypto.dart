import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/ecc/api.dart';
import 'package:pointycastle/ecc/curves/brainpoolp320r1.dart';
import 'package:pointycastle/export.dart';
import 'package:pointycastle/key_generators/api.dart';
import 'package:pointycastle/key_generators/ec_key_generator.dart';
import 'package:pointycastle/key_generators/rsa_key_generator.dart';
import 'package:pointycastle/random/fortuna_random.dart';

class AppCrypto {
  static Uint8List _generateRandomBytes(int length) {
    final random = Random.secure();
    var values = List<int>.generate(length, (index) => random.nextInt(256));
    return Uint8List.fromList(values);
  }

  static Uint8List encryptAES(
      Uint8List plaintext, Uint8List key, Uint8List iv) {
    final blockCipher = BlockCipher('AES');

    final params = ParametersWithIV<KeyParameter>(
        KeyParameter(key), _generateRandomBytes(16));

    blockCipher.init(true, params);

    final encrypted = blockCipher.process(Uint8List.fromList(plaintext));

    return encrypted;
  }

  static Uint8List decryptAES(Uint8List encryptedData, Uint8List key) {
    Uint8List iv = encryptedData.sublist(0, 16);

    final blockCipher = BlockCipher('AES');

    final params = ParametersWithIV<KeyParameter>(KeyParameter(key), iv);

    blockCipher.init(false, params);

    final decrypted = blockCipher.process(encryptedData.sublist(16));

    return decrypted;
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

  static AsymmetricKeyPair<ECPublicKey, ECPrivateKey> generateRSAKeyPair(
      {int bitLength = 2048}) {
    final keyGen = ECKeyGenerator()
      ..init(ParametersWithRandom(
          ECKeyGeneratorParameters(ECCurve_secp256r1()), _secureRandom()));
    final pair = keyGen.generateKeyPair();
    final public = pair.publicKey as ECPublicKey;
    final private = pair.privateKey as ECPrivateKey;

    return AsymmetricKeyPair<ECPublicKey, ECPrivateKey>(public, private);
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
    var byteArray = bigInt
        .toUnsigned(8 * ((bigInt.bitLength + 7) >> 3))
        .toRadixString(16)
        .padLeft((bigInt.bitLength + 7) >> 3 * 2, '0');

    if (bigInt < BigInt.zero) {
      var negativeByteArray = (BigInt.one << (byteArray.length * 4)) + bigInt;
      byteArray = negativeByteArray
          .toUnsigned(8 * ((negativeByteArray.bitLength + 7) >> 3))
          .toRadixString(16)
          .padLeft((negativeByteArray.bitLength + 7) >> 3 * 2, '0');
    }

    var result = Uint8List((byteArray.length / 2).ceil());
    for (var i = 0; i < result.length; i++) {
      result[i] = int.parse(byteArray.substring(i * 2, i * 2 + 2), radix: 16);
    }

    return result;
  }
}
