import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:pointycastle/api.dart';

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
}
