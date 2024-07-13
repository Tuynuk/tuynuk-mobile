enum ReceiverStateEnum {
  loading("Loading"),
  generatingKey("Generating key pair"),
  sharedKeyDeriving("Shared key calculation"),
  failed("Failed"),
  initial("Initial"),
  connection("Connecting to the server"),
  connected("Connected"),
  connectionError("Connection error"),
  identifierGenerated("Identifier generated"),
  creatingSession("Creating session"),
  encryptionFile("Encrypting file"),
  writingFile("Writing file"),
  writingEncryptedFile("Writing encrypted file"),
  fileIdReceived("File id received"),
  decryptionFile("Decryption file"),
  downloadingFile("Downloading file"),
  clearing("Clearing");

  const ReceiverStateEnum(this.value);

  final String value;
}

class ReceiverStateController {
  ReceiverStateEnum _currentState = ReceiverStateEnum.initial;

  bool get canReceive =>
      _currentState == ReceiverStateEnum.connectionError ||
      _currentState == ReceiverStateEnum.initial;

  ReceiverStateEnum get state => _currentState;

  List<ReceiverStateEnum> get history => _history;
  final List<Function> _listeners = [];
  final List<ReceiverStateEnum> _history = [];

  void onStateChanged(Function(ReceiverStateEnum state) listener) {
    _listeners.add(listener);
  }

  _notify() {
    for (var e in _listeners) {
      e.call(_currentState);
    }
  }

  void setState(ReceiverStateEnum state) {
    _currentState = state;
    _history.add(state);
    if (state == ReceiverStateEnum.failed ||
        state == ReceiverStateEnum.initial) {
      restart();
    }
    _notify();
  }

  void restart() {
    _currentState = ReceiverStateEnum.initial;
  }
}
