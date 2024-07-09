import 'package:signalr_netcore/msgpack_hub_protocol.dart';
import 'package:signalr_netcore/signalr_client.dart';

class ConnectionClient {
  final EventListeners eventNotifier;
  late HubConnection? _connection;

  void buildSignalR() {
    _connection = HubConnectionBuilder()
        .withUrl("serverUrl")
        .withHubProtocol(MessagePackHubProtocol())
        .withSingleListener(true)
        .build();
  }

  Future<void> connect() async {
    await _connection?.start();
  }

  Future<void> disconnect() async {
    await _connection?.stop();
  }

  ConnectionClient(this.eventNotifier) {
    buildSignalR();
  }
}

abstract class EventListeners {
  void onPublicKeyReceived(String publicKey);
}
