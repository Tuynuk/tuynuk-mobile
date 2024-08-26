// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.


import 'dart:convert';
import 'dart:typed_data';

import 'package:safe_file_sender/crypto/crypto_core.dart';

void main() {
  final fileEncryptedKey = AppCrypto.sha256Digest(
      utf8.encode("1234"),
      salt: [243, 98, 82, 171, 0, 136, 111, 36, 75, 225, 35, 248, 225, 99, 67, 139]);
  print(fileEncryptedKey);
}
