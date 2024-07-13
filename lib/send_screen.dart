import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pointycastle/ecc/api.dart';
import 'package:safe_file_sender/crypto/crypto.dart';
import 'package:safe_file_sender/dev/logger.dart';
import 'package:safe_file_sender/io/socket_client.dart';
import 'package:safe_file_sender/models/sender_state_enum.dart';
import 'package:safe_file_sender/utils/file_utils.dart';
import 'package:safe_file_sender/widgets/scale_tap.dart';
import 'package:safe_file_sender/widgets/snap_effect.dart';

class SendScreen extends StatefulWidget {
  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> implements SenderListeners {
  final GlobalKey<SnappableState> _key = GlobalKey();
  late ConnectionClient _connectionClient;
  File? _selectedFile;
  ECPrivateKey? _privateKey;
  ECPublicKey? _publicKey;
  Uint8List? _sharedKey;
  List<int> _fileBytes = [];

  @override
  void initState() {
    _connectionClient = ConnectionClient(this);

    _senderStateController.onStateChanged((state) async {
      if (state == SenderStateEnum.failed) {
        _connectionClient.disconnect();
      }
    });
    super.initState();
  }

  final TextEditingController _textEditingController = TextEditingController();
  final SenderStateController _senderStateController = SenderStateController();

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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(24),
            ),
            TextField(
              style: const TextStyle(fontFamily: "Hack", color: Colors.white),
              controller: _textEditingController,
              decoration: InputDecoration(
                hintStyle:
                    const TextStyle(color: Colors.white54, fontFamily: "Hack"),
                hintText: "Input session id",
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white60)),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(12),
            ),
            ElevatedButton(
              onPressed: () {
                if (_textEditingController.text.trim().isNotEmpty &&
                    _selectedFile != null &&
                    _senderStateController.canSend) {
                  _send();
                }
              },
              child: (!_senderStateController.canSend)
                  ? const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      "Send",
                      style: TextStyle(fontFamily: "Hack"),
                    ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
            ),
            ScaleTap(
              onPressed: () async {
                if (_selectedFile != null) return;
                final files =
                    (await FilePicker.platform.pickFiles())?.files ?? [];
                final file = files.first;
                _selectedFile = File(file.path ?? "");
                _fileBytes = _selectedFile!.readAsBytesSync().toList();
                setState(() {});
              },
              child: Snappable(
                key: _key,
                onSnapped: () {
                  _clear();
                },
                child: Container(
                  height: 32,
                  alignment: Alignment.center,
                  child: _selectedFile == null
                      ? const Text(
                          "Select file",
                          style: TextStyle(
                              color: Colors.white, fontFamily: "Hack"),
                        )
                      : ListView.builder(
                          itemExtent: 34,
                          itemCount: (_fileBytes.length * .3).toInt(),
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (e, index) {
                            final bit = _fileBytes[index]
                                .toRadixString(2)
                                .padLeft(8, '0');
                            return Text(
                              bit,
                              style: const TextStyle(color: Colors.white),
                            );
                          },
                        ),
                ),
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
                    ..._senderStateController.history.map(
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
          ],
        ),
      ),
    );
  }

  Future<void> _send() async {
    setState(() {
      _senderStateController.history.clear();
      _senderStateController.setState(SenderStateEnum.loading);
    });
    await _connectionClient.connect();

    setState(() {
      _senderStateController.setState(SenderStateEnum.connection);
    });
    if (_connectionClient.isConnected) {
      setState(() {
        _senderStateController.setState(SenderStateEnum.connected);
        _senderStateController.setState(SenderStateEnum.generatingKey);
      });
      final pair = AppCrypto.generateECKeyPair();
      _privateKey = pair.privateKey;
      _publicKey = pair.publicKey;

      setState(() {
        _senderStateController.setState(SenderStateEnum.joining);
      });
      _connectionClient.joinSession(
          _textEditingController.text.trim().toUpperCase(),
          AppCrypto.encodeECPublicKey(_publicKey!));
    } else {
      setState(() {
        _senderStateController.setState(SenderStateEnum.connectionError);
      });
    }
  }

  @override
  Future<void> onConnected() async {
    //
  }

  @override
  Future<void> onPublicKeyReceived(String publicKey) async {
    logMessage("PublicKey : $publicKey");
    setState(() {
      _senderStateController.setState(SenderStateEnum.sharedKeyDeriving);
    });
    final sharedKey = AppCrypto.deriveSharedSecret(
        _privateKey!, AppCrypto.decodeECPublicKey(publicKey));
    logMessage("Shared key derived [${sharedKey.length}] $sharedKey");
    _sharedKey = sharedKey;

    setState(() {
      _senderStateController.setState(SenderStateEnum.encryptionFile);
    });
    final encrypted =
        AppCrypto.encryptAES(_selectedFile!.readAsBytesSync(), _sharedKey!);

    setState(() {
      _senderStateController.setState(SenderStateEnum.writingEncryptedFile);
    });
    final encFile = File(
        "${(await getApplicationCacheDirectory()).path}/enc_${FileUtils.fileName(_selectedFile!.path)}");
    encFile.writeAsBytesSync(encrypted);

    setState(() {
      _senderStateController.setState(SenderStateEnum.sendingFile);
    });
    final sent = await _connectionClient.sendFile(
        encFile.path,
        FileUtils.fileName(_selectedFile!.path),
        _textEditingController.text.toUpperCase().trim());

    logMessage("Sent : $sent");
    _key.currentState?.snap();
  }

  _clear() {
    setState(() {
      _senderStateController.setState(SenderStateEnum.initial);
    });
    _textEditingController.clear();
    _publicKey = null;
    _privateKey = null;
    _fileBytes = [];
    _selectedFile = null;
    _key.currentState?.reset();
  }

  @override
  void dispose() {
    _connectionClient.disconnect();
    super.dispose();
  }
}
