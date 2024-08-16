import 'dart:typed_data';

class AppTempData {
  Uint8List? pinDerivedKey;

  void setPinDerivedKey(Uint8List value) {
    pinDerivedKey = value;
  }

  Uint8List? getPinDerivedKey() => pinDerivedKey;
}
