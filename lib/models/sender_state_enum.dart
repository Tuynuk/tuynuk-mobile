enum SenderStateEnum {
  loading("Loading"),
  generatingKey("Generating key pair"),
  sharedKeyDeriving("Shared key calculation"),
  failed("Failed"),
  sendingFile("Sending encrypted file"),
  initial("Initial"),
  connection("Connecting to the server"),
  connectionError("Connection error"),
  connected("Connected"),
  joining("Joining to the session"),
  encryptionFile("Encrypting file"),
  writingFile("Writing file"),
  writingEncryptedFile("Writing encrypted file"),
  generatingHmac("Generating HMAC"),
  clearing("Clearing");

  const SenderStateEnum(this.value);

  final String value;
}

class SenderStateController {
  SenderStateEnum _currentState = SenderStateEnum.initial;

  SenderStateEnum get state => _currentState;

  bool get canSend =>
      _currentState == SenderStateEnum.connectionError ||
      _currentState == SenderStateEnum.initial;

  List<SenderStateEnum> get history => _history;
  final List<Function> _listeners = [];
  final List<SenderStateEnum> _history = [];

  void onStateChanged(Function(SenderStateEnum state) listener) {
    _listeners.add(listener);
  }

  _notify() {
    for (var e in _listeners) {
      e.call(_currentState);
    }
  }

  void setState(SenderStateEnum state) {
    _currentState = state;
    _history.add(state);
    if (state == SenderStateEnum.failed || state == SenderStateEnum.initial) {
      restart();
    }
    _notify();
  }

  void restart() {
    _currentState = SenderStateEnum.initial;
  }
}
