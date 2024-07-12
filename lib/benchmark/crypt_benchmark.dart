import 'package:safe_file_sender/crypto/crypto.dart';

void main() {
  final pair = AppCrypto.generateECKeyPair();
  print(AppCrypto.deriveSharedSecret(pair.privateKey, pair.publicKey));
  final publicBase64 = AppCrypto.encodeECPublicKey(pair.publicKey);
  print(publicBase64);
  print(AppCrypto.decodeECPublicKey(publicBase64).Q);
}
