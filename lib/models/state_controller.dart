enum TransferStateEnum {
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
  identifierGenerated("Identifier generated"),
  creatingSession("Creating session"),
  fileIdReceived("File id received"),
  decryptionFile("Decryption file"),
  downloadingFile("Downloading file"),
  checkingHmac("Checking data integrity"),
  hmacError("File corrupted"),
  hmacSuccess("File NOT corrupted"),
  clearing("Clearing");

  const TransferStateEnum(this.value);

  final String value;
}

class TransferStateController {
  TransferStateEnum _currentState = TransferStateEnum.initial;

  TransferStateEnum get state => _currentState;

  bool get canSend =>
      _currentState == TransferStateEnum.connectionError ||
      _currentState == TransferStateEnum.initial;

  bool get canReceive =>
      _currentState == TransferStateEnum.connectionError ||
      _currentState == TransferStateEnum.initial;

  List<TransferStateEnum> get history => _history;
  final List<Function> _listeners = [];
  final List<TransferStateEnum> _history = [];

  void onStateChanged(Function(TransferStateEnum state) listener) {
    _listeners.add(listener);
  }

  _notify() {
    for (var e in _listeners) {
      e.call(_currentState);
    }
  }

  void logStatus(TransferStateEnum state) {
    _currentState = state;
    _history.add(state);
    if (state == TransferStateEnum.failed ||
        state == TransferStateEnum.initial) {
      restart();
    }
    _notify();
  }

  void restart() {
    _currentState = TransferStateEnum.initial;
  }
}
