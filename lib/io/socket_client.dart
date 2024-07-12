import 'package:dio/dio.dart';
import 'package:safe_file_sender/dev/logger.dart';
import 'package:signalr_netcore/json_hub_protocol.dart';
import 'package:signalr_netcore/signalr_client.dart';

class ConnectionClient {
  final BaseEventListeners _eventNotifier;
  late HubConnection? _connection;
  final Dio _dio = Dio(
    BaseOptions(baseUrl: "http://192.168.1.18:8088/api/"),
  );

  Dio get dio => _dio;

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

  Future<bool> sendFile(
      String filePath, String fileName, String sessionId) async {
    FormData data = FormData.fromMap({
      "formFile": await MultipartFile.fromFile(filePath, filename: fileName),
    });

    final response =
        await _dio.post("Files/UploadFile", data: data, queryParameters: {
      "sessionIdentifier": sessionId,
    });
    return response.statusCode == 200;
  }

  Future<void> _listenEvents() async {
    _connection?.on('OnSessionCreated', (message) async {
      _log("OnSessionCreated : $message");
      (_eventNotifier as ReceiverListeners)
          .onIdentifierReceived(message![0].toString());
    });
    _connection?.on('OnSessionReady', (message) async {
      _log("OnSessionReady : $message");
      _eventNotifier.onPublicKeyReceived(message![0].toString());
    });
    _connection?.on('OnFileUploaded', (message) async {
      _log("OnFileUploaded : $message");
      (_eventNotifier as ReceiverListeners)
          .onFileReceived(message![0].toString());
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

abstract class BaseEventListeners {
  Future<void> onPublicKeyReceived(String publicKey);

  Future<void> onConnected();
}

abstract class ReceiverListeners extends BaseEventListeners {
  Future<void> onIdentifierReceived(String publicKey);

  Future<void> onFileReceived(String fileId);
}

abstract class SenderListeners extends BaseEventListeners {}
