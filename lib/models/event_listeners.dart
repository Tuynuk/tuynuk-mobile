import 'package:safe_file_sender/models/base/base_event_listener.dart';

abstract class ReceiverListeners extends BaseEventListeners {
  Future<void> onIdentifierReceived(String publicKey);

  Future<void> onFileReceived(String fileId, String fileName, String hmac);
}

abstract class SenderListeners extends BaseEventListeners {}
