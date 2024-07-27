import 'dart:io';
import 'dart:typed_data';

import 'package:background_downloader/background_downloader.dart';
import 'package:dio/dio.dart';
import 'package:safe_file_sender/dev/logger.dart';
import 'package:safe_file_sender/io/downloader.dart';
import 'package:signalr_netcore/json_hub_protocol.dart';
import 'package:signalr_netcore/signalr_client.dart';

class ConnectionClient {
  final BaseEventListeners _eventNotifier;
  late HubConnection? _connection;
  static String baseUrl = "http://192.168.1.18:8088/api/";
  final Dio _dio = Dio(
    BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(minutes: 5),
        sendTimeout: const Duration(minutes: 5),
        receiveTimeout: const Duration(minutes: 5)),
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
    try {
      _connection?.send("JoinSession", args: [
        {
          "identifier": identifier,
          "publicKey": publicKey,
        }
      ]).onError((value, trace) {
        _log(trace.toString());
      }).catchError((onError) {
        _log(onError);
      }).then((value) {
        logMessage("Join session end");
      });
    } catch (e) {
      logMessage(e.toString());
    }
  }

  Future<bool> sendFile(
      String filePath, String fileName, String sessionId, String hmac) async {
    try {
      FormData data = FormData.fromMap({
        "formFile": await MultipartFile.fromFile(filePath, filename: fileName),
      });

      await Downloader.uploadFile(filePath, sessionId, hmac,
          onSend: (progress) {
        //
      });
      // final response =
      //     await _dio.post("Files/UploadFile", data: data, queryParameters: {
      //   "sessionIdentifier": sessionId,
      //   "HMAC": hmac,
      // });
      return true;
    } catch (e) {
      return false;
    }
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
      (_eventNotifier as ReceiverListeners).onFileReceived(
        message![0].toString(),
        message[1].toString(),
        message[2].toString(),
      );
    });
  }

  bool get isConnected => _connection?.state == HubConnectionState.Connected;

  Future<void> connect() async {
    try {
      if (_connection?.state != HubConnectionState.Disconnected) return;
      await _connection?.start();
      _log(
          "IsConnected : ${_connection?.state == HubConnectionState.Connected}");
      if (_connection?.state == HubConnectionState.Connected) {
        _listenEvents();
        _eventNotifier.onConnected();
      }
    } catch (e) {
      logMessage(e.toString());
    }
  }

  Future<void> disconnect() async {
    await _connection?.stop();
    _dio.close(force: true);
  }

  ConnectionClient(this._eventNotifier) {
    buildSignalR();
  }

  _log(dynamic message) => logMessage(message);

  Future<Map<String, dynamic>> fetchHeaders(String url) async {
    final response = await dio.head(url);
    return response.headers.map;
  }

  Future<void> downloadFile(String fileId, String fileName, String savePath,
      {required Function(Uint8List bytes, String fileName) onSuccess,
      required Function() onError}) async {
    try {
      Downloader.download(fileId, fileName,
          onSuccess: (String downloadedPath) async {
        onSuccess.call(
          File(downloadedPath).readAsBytesSync(),
          fileName,
        );
      });
    } catch (e) {
      onError.call();
      logMessage('Download failed: $e');
    }
  }
}

abstract class BaseEventListeners {
  Future<void> onPublicKeyReceived(String publicKey);

  Future<void> onConnected();
}

abstract class ReceiverListeners extends BaseEventListeners {
  Future<void> onIdentifierReceived(String publicKey);

  Future<void> onFileReceived(String fileId, String fileName, String hmac);
}

abstract class SenderListeners extends BaseEventListeners {}
