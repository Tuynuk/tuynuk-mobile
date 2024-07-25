import 'dart:io';

import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pointycastle/ecc/api.dart';
import 'package:safe_file_sender/io/socket_client.dart';
import 'package:safe_file_sender/models/state_controller.dart';
import 'package:safe_file_sender/utils/string_utils.dart';
import 'package:safe_file_sender/widgets/encrypted_key_matrix.dart';
import 'package:safe_file_sender/widgets/status_logger.dart';
import 'package:share_plus/share_plus.dart';

import 'crypto/crypto.dart';
import 'dev/logger.dart';

class ReceiveScreen extends StatefulWidget {
  const ReceiveScreen({super.key});

  @override
  State<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<ReceiveScreen> implements ReceiverListeners {
  late ConnectionClient _connectionClient;
  ECPrivateKey? _privateKey;
  Uint8List? _sharedKey;
  String? _identifier;
  String? _sharedKeyDigest;

  @override
  void initState() {
    _connectionClient = ConnectionClient(this);
    super.initState();
  }

  final TransferStateController _receiverStateController = TransferStateController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      bottomNavigationBar: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            alignment: Alignment.center,
            width: 42,
            height: 42,
            decoration:
                BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.white12),
            margin: const EdgeInsets.all(24),
            child: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(
                Icons.close,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Container(
        margin: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(12),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_receiverStateController.canReceive) {
                    _receive();
                  }
                },
                child: (!_receiverStateController.canReceive)
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "Create session",
                        style: TextStyle(fontFamily: "Hack"),
                      ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
              ),
              StatusLogger(controller: _receiverStateController),
              const Padding(
                padding: EdgeInsets.all(24),
              ),
              if (_identifier != null)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () {
                        if (_identifier == null) return;
                        Clipboard.setData(ClipboardData(text: _identifier!));
                      },
                      child: Text(
                        _identifier!,
                        style:
                            const TextStyle(fontFamily: "Hack", color: Colors.white, fontSize: 20),
                      ),
                    ),
                    const Text(
                      "Tap to copy",
                      style: TextStyle(fontFamily: "Hack", color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              const Padding(
                padding: EdgeInsets.all(6),
              ),
              if (_sharedKeyDigest != null)
                EncryptionKeyWidget(
                  keyMatrix: StringUtils.splitByLength(_sharedKeyDigest!, 2),
                )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _receive() async {
    _receiverStateController.history.clear();
    _receiverStateController.setState(TransferStateEnum.connection);
    await _connectionClient.connect();

    if (!context.mounted) return;
    if (_connectionClient.isConnected) {
      _receiverStateController.setState(TransferStateEnum.connected);
      _receiverStateController.setState(TransferStateEnum.generatingKey);
      final keyPair = AppCrypto.generateECKeyPair();
      _privateKey = keyPair.privateKey;
      _receiverStateController.setState(TransferStateEnum.creatingSession);
      _connectionClient.createSession(AppCrypto.encodeECPublicKey(keyPair.publicKey));
    } else {
      _receiverStateController.setState(TransferStateEnum.connectionError);
    }
  }

  @override
  void dispose() {
    _connectionClient.disconnect();
    super.dispose();
  }

  @override
  Future<void> onConnected() async {
    //
  }

  @override
  Future<void> onPublicKeyReceived(String publicKey) async {
    logMessage("PublicKey : $publicKey");

    _receiverStateController.setState(TransferStateEnum.sharedKeyDeriving);
    final sharedKey =
        AppCrypto.deriveSharedSecret(_privateKey!, AppCrypto.decodeECPublicKey(publicKey));
    logMessage("Shared key derived [${sharedKey.length}] $sharedKey");
    _sharedKey = sharedKey;
    _sharedKeyDigest = hex.encode(AppCrypto.sha256Digest(_sharedKey!));
    setState(() {});
  }

  @override
  Future<void> onIdentifierReceived(String identifier) async {
    _identifier = identifier;
    _receiverStateController.setState(TransferStateEnum.identifierGenerated);
    setState(() {});
  }

  @override
  Future<void> onFileReceived(String fileId) async {
    _receiverStateController.setState(TransferStateEnum.fileIdReceived);
    final path = File((await getApplicationCacheDirectory()).path);
    _receiverStateController.setState(TransferStateEnum.downloadingFile);
    _connectionClient.downloadFile(fileId, path.path, onSuccess: (bytes, fileName, hmac) async {
      _receiverStateController.setState(TransferStateEnum.checkingHmac);
      final hmacLocal = hex.encode(AppCrypto.generateHMAC(_sharedKey!, bytes));
      if (hmacLocal == hmac) {
        logMessage("HMAC check success");
      } else {
        logMessage("HMAC check failed");
        _connectionClient.disconnect();
        return;
      }
      _receiverStateController.setState(TransferStateEnum.decryptionFile);
      final decBytes = AppCrypto.decryptAES(bytes, _sharedKey!);
      _clear();
      final dec = File("${path.path}/${DateTime.now().millisecondsSinceEpoch}_$fileName");
      _receiverStateController.setState(TransferStateEnum.writingFile);
      dec.writeAsBytesSync(decBytes);

      await _connectionClient.disconnect();
      _clear();
      Share.shareXFiles([
        XFile(dec.path),
      ]).then((value) {
        dec.delete(recursive: true);
      });
    }, onError: () {
      _clear();
    });
  }

  _clear() {
    setState(() {
      _sharedKeyDigest = null;
      _receiverStateController.setState(TransferStateEnum.initial);
      _privateKey = null;
      _identifier = null;
    });
  }
}
