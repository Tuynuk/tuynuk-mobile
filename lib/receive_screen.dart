import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pointycastle/ecc/api.dart';
import 'package:safe_file_sender/dialogs/receive_bottom_sheet_dialog.dart';
import 'package:safe_file_sender/io/socket_client.dart';
import 'package:safe_file_sender/widgets/button.dart';
import 'package:safe_file_sender/widgets/snap_effect.dart';
import 'package:share_plus/share_plus.dart';

import 'crypto/crypto.dart';
import 'dev/logger.dart';

class ReceiveScreen extends StatefulWidget {
  ReceiveScreen({super.key});

  @override
  State<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<ReceiveScreen>
    implements ReceiverListeners {
  late ConnectionClient _connectionClient;
  ECPrivateKey? _privateKey;
  Uint8List? _sharedKey;

  @override
  void initState() {
    _connectionClient = ConnectionClient(this);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Button(
            onTap: () {
              _receive();
            },
            child: const Icon(Icons.receipt),
          ),
        ],
      ),
    );
  }

  Future<void> _receive() async {
    await _connectionClient.connect();

    if (!context.mounted) return;
    ReceiveBottomSheetDialog.show(context, onClose: () async {
      // await _connectionClient.disconnect();
    });

    if (_connectionClient.isConnected) {
      final keyPair = AppCrypto.generateECKeyPair();
      _privateKey = keyPair.privateKey;
      _connectionClient
          .createSession(AppCrypto.encodeECPublicKey(keyPair.publicKey));
    }
  }

  @override
  Future<void> onConnected() async {
    //
  }

  @override
  Future<void> onPublicKeyReceived(String publicKey) async {
    logMessage("PublicKey : $publicKey");
    final sharedKey = AppCrypto.deriveSharedSecret(
        _privateKey!, AppCrypto.decodeECPublicKey(publicKey));
    logMessage("Shared key derived [${sharedKey.length}] $sharedKey");
    _sharedKey = sharedKey;
  }

  @override
  Future<void> onIdentifierReceived(String publicKey) async {
    //
  }

  @override
  Future<void> onFileReceived(String fileId) async {
    final path = File((await getApplicationCacheDirectory()).path);

    _connectionClient.downloadFile(fileId, path.path,
        onSuccess: (bytes, fileName) async {
      final decBytes = await AppCrypto.decryptAESInIsolate(bytes, _sharedKey!);
      _clear();
      final dec = File(
          "${path.path}/${DateTime.now().millisecondsSinceEpoch}_$fileName");
      dec.writeAsBytesSync(decBytes);
      await _connectionClient.disconnect();
      Share.shareXFiles([
        XFile(dec.path),
      ]).then((value) {
        dec.delete(recursive: true);
      });
    });
  }

  _clear() {
    _privateKey = null;
  }
}
