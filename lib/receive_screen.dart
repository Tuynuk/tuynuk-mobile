import 'dart:io';

import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pointycastle/ecc/api.dart';
import 'package:safe_file_sender/io/socket_client.dart';
import 'package:safe_file_sender/models/receiver_state_enum.dart';
import 'package:safe_file_sender/utils/string_utils.dart';
import 'package:safe_file_sender/widgets/encrypted_key_matrix.dart';
import 'package:share_plus/share_plus.dart';

import 'crypto/crypto.dart';
import 'dev/logger.dart';

class ReceiveScreen extends StatefulWidget {
  const ReceiveScreen({super.key});

  @override
  State<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<ReceiveScreen>
    implements ReceiverListeners {
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

  final ReceiverStateController _receiverStateController =
      ReceiverStateController();

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
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12), color: Colors.white12),
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
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white12,
                ),
                height: 300,
                width: MediaQuery.sizeOf(context).width,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ..._receiverStateController.history.map(
                        (e) => Container(
                          margin: const EdgeInsets.only(top: 4, left: 4),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            e.value,
                            style: const TextStyle(
                                color: Colors.white60,
                                fontFamily: "Hack",
                                fontSize: 8),
                            textAlign: TextAlign.start,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
                        style: const TextStyle(
                            fontFamily: "Hack",
                            color: Colors.white,
                            fontSize: 20),
                      ),
                    ),
                    const Text(
                      "Tap to copy",
                      style: TextStyle(
                          fontFamily: "Hack",
                          color: Colors.white54,
                          fontSize: 12),
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
    setState(() {
      _receiverStateController.history.clear();
      _receiverStateController.setState(ReceiverStateEnum.connection);
    });
    await _connectionClient.connect();

    if (!context.mounted) return;
    if (_connectionClient.isConnected) {
      setState(() {
        _receiverStateController.setState(ReceiverStateEnum.connected);
        _receiverStateController.setState(ReceiverStateEnum.generatingKey);
      });
      final keyPair = AppCrypto.generateECKeyPair();
      _privateKey = keyPair.privateKey;
      setState(() {
        _receiverStateController.setState(ReceiverStateEnum.creatingSession);
      });
      _connectionClient
          .createSession(AppCrypto.encodeECPublicKey(keyPair.publicKey));
    } else {
      setState(() {
        _receiverStateController.setState(ReceiverStateEnum.connectionError);
      });
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

    setState(() {
      _receiverStateController.setState(ReceiverStateEnum.sharedKeyDeriving);
    });
    final sharedKey = AppCrypto.deriveSharedSecret(
        _privateKey!, AppCrypto.decodeECPublicKey(publicKey));
    logMessage("Shared key derived [${sharedKey.length}] $sharedKey");
    _sharedKey = sharedKey;
    _sharedKeyDigest = hex.encode(AppCrypto.sha256Digest(_sharedKey!));
    setState(() {});
  }

  @override
  Future<void> onIdentifierReceived(String identifier) async {
    _identifier = identifier;
    setState(() {
      _receiverStateController.setState(ReceiverStateEnum.identifierGenerated);
    });
    setState(() {});
  }

  @override
  Future<void> onFileReceived(String fileId) async {
    setState(() {
      _receiverStateController.setState(ReceiverStateEnum.fileIdReceived);
    });
    final path = File((await getApplicationCacheDirectory()).path);
    setState(() {
      _receiverStateController.setState(ReceiverStateEnum.downloadingFile);
    });
    _connectionClient.downloadFile(fileId, path.path,
        onSuccess: (bytes, fileName, hmac) async {
      setState(() {
        _receiverStateController.setState(ReceiverStateEnum.checkingHmac);
        final hmacLocal = hex.encode(AppCrypto.generateHMAC(_sharedKey!, bytes));
        if (hmacLocal == hmac) {
          logMessage("HMAC check success");
        } else {
          logMessage("HMAC check failed");
          _connectionClient.disconnect();
          return;
        }
      });
      setState(() {
        _receiverStateController.setState(ReceiverStateEnum.decryptionFile);
      });
      final decBytes = AppCrypto.decryptAES(bytes, _sharedKey!);
      _clear();
      final dec = File(
          "${path.path}/${DateTime.now().millisecondsSinceEpoch}_$fileName");
      setState(() {
        _receiverStateController.setState(ReceiverStateEnum.writingFile);
      });
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
      _receiverStateController.setState(ReceiverStateEnum.initial);
      _privateKey = null;
      _identifier = null;
    });
  }
}
