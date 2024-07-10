import 'package:safe_file_sender/dev/logger.dart';
import 'package:signalr_netcore/json_hub_protocol.dart';
import 'package:signalr_netcore/signalr_client.dart';

class ConnectionClient {
  final EventListeners _eventNotifier;
  late HubConnection? _connection;

  void buildSignalR() {
    _connection = HubConnectionBuilder()
        .withUrl("http://192.168.1.18:8088/hubs/session")
        .withHubProtocol(JsonHubProtocol())
        .withSingleListener(true)
        .build();
  }

  Future<void> createSession(String publicKeyBase64) async {
    _log("Creating session : $isConnected");
    _connection?.send("CreateSession", args: [
      {
        "publicKey": publicKeyBase64,
      }
    ]);
  }

  Future<void> joinSession(String identifier, String publicKey) async {
    _connection?.send("JoinSession", args: [
      {
        "identifier": identifier,
        "publicKey": publicKey,
      }
    ]);
  }

  Future<void> sendFile(String fileBase64, String fileName) async {
    _connection?.send("SendFile", args: [
      {
        "fileName": fileName,
        "base64": fileBase64,
      }
    ]);
  }

  Future<void> _listenEvents() async {
    _connection?.on('OnSessionCreated', (message) async {
      _log("OnSessionCreated : $message");
      _eventNotifier.onIdentifierReceived(message![0].toString());
    });
    _connection?.on('OnSessionReady', (message) async {
      _log("OnSessionReady : $message");
      _eventNotifier.onPublicKeyReceived(message![0].toString());
    });
    _connection?.on('OnFiledReceived', (message) async {
      _log("OnFiledReceived : $message");
      _eventNotifier.onFileReceived(message![0].toString());
    });
  }

  bool get isConnected => _connection?.state == HubConnectionState.Connected;

  Future<void> connect() async {
    if (_connection?.state != HubConnectionState.Disconnected) return;
    await _connection?.start();
    _log("IsConnected : ${_connection?.state == HubConnectionState.Connected}");
    if (_connection?.state == HubConnectionState.Connected) {
      _listenEvents();
      _eventNotifier.onConnected();
    }
  }

  Future<void> disconnect() async {
    await _connection?.stop();
  }

  ConnectionClient(this._eventNotifier) {
    buildSignalR();
  }

  _log(dynamic message) => logMessage(message);
}

abstract class EventListeners {
  Future<void> onPublicKeyReceived(String publicKey);

  Future<void> onIdentifierReceived(String publicKey);

  Future<void> onConnected();

  Future<void> onFileReceived(String content);
}
