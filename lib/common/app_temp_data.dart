import 'dart:typed_data';

class AppTempData {
  Uint8List? _pinDerivedKey;
  Uint8List? _pinDerivedKeySalt;
  String? _pin;

  void setPinDerivedKey(Uint8List value) {
    _pinDerivedKey = value;
  }

  void setPin(String value) {
    _pin = value;
  }

  void setPinDerivedKeySalt(Uint8List value) {
    _pinDerivedKeySalt = value;
  }

  Uint8List? getPinDerivedKey() => _pinDerivedKey;

  String? getPin() => _pin;

  Uint8List? getPinDerivedKeySalt() => _pinDerivedKeySalt;
}
