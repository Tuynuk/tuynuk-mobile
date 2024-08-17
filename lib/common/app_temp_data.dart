import 'dart:typed_data';

class AppTempData {
  Uint8List? _pinDerivedKey;
  Uint8List? _pinDerivedKeySalt;

  void setPinDerivedKey(Uint8List value) {
    _pinDerivedKey = value;
  }

  void setPinDerivedKeySalt(Uint8List value) {
    _pinDerivedKey = value;
  }

  Uint8List? getPinDerivedKey() => _pinDerivedKey;

  Uint8List? getPinDerivedKeySalt() => _pinDerivedKeySalt;
}
