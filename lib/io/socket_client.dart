import 'package:socket_io_client/socket_io_client.dart';

class SocketClient {
  final EventListeners eventNotifier;
  final Socket _socket = io(
      'http://localhost:3000',
      OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setExtraHeaders({'foo': 'bar'})
          .build());

  void connect() {
    _socket.connect();
  }

  SocketClient(this.eventNotifier);
}

abstract class EventListeners {
  void onPublicKeyReceived(String publicKey);
}
