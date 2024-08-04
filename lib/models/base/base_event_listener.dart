abstract class BaseEventListeners {
  Future<void> onPublicKeyReceived(String publicKey);

  Future<void> onConnected();
}
