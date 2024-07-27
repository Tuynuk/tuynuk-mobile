import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pointycastle/ecc/api.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:safe_file_sender/crypto/crypto.dart';
import 'package:safe_file_sender/dev/logger.dart';
import 'package:safe_file_sender/io/socket_client.dart';
import 'package:safe_file_sender/models/state_controller.dart';
import 'package:safe_file_sender/utils/file_utils.dart';
import 'package:safe_file_sender/utils/string_utils.dart';
import 'package:safe_file_sender/widgets/encrypted_key_matrix.dart';
import 'package:safe_file_sender/widgets/scale_tap.dart';
import 'package:safe_file_sender/widgets/snap_effect.dart';
import 'package:safe_file_sender/widgets/status_logger.dart';

class SendScreen extends StatefulWidget {
  final SharedMediaFile? sharedFile;

  const SendScreen({super.key, required this.sharedFile});

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
  String? _sharedKeyDigest;
  List<int> _fileBytes = [];

  @override
  void initState() {
    if (widget.sharedFile != null) {
      _selectedFile = File(widget.sharedFile!.path);
      _fileBytes = _selectedFile!.readAsBytesSync();
    }
    _connectionClient = ConnectionClient(this);

    _senderStateController.onStateChanged((state) async {
      if (state == TransferStateEnum.failed) {
        _connectionClient.disconnect();
      }
    });
    super.initState();
  }

  final TextEditingController _textEditingController = TextEditingController();
  final TransferStateController _senderStateController =
  TransferStateController();

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
                padding: EdgeInsets.all(24),
              ),
              TextField(
                style: const TextStyle(fontFamily: "Hack", color: Colors.white),
                controller: _textEditingController,
                decoration: InputDecoration(
                  hintStyle: const TextStyle(
                      color: Colors.white54, fontFamily: "Hack"),
                  hintText: "Input session id",
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white60)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(12),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_textEditingController.text
                      .trim()
                      .isNotEmpty &&
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
                  if (_senderStateController.canSend) {
                    final files =
                        (await FilePicker.platform.pickFiles())?.files ?? [];
                    if (files.isEmpty) return;
                    final file = File(files.first.path!);
                    double sizeInMb = file.lengthSync() / (1024 * 1024);
                    if (sizeInMb > 100) return;
                    _selectedFile = file;

                    _fileBytes = _selectedFile!.readAsBytesSync().toList();
                    setState(() {});
                  }
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
              StatusLogger(controller: _senderStateController),
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

  Future<void> _send() async {
    _senderStateController.history.clear();
    _senderStateController.logStatus(TransferStateEnum.loading);
    setState(() {});
    await _connectionClient.connect();

    _senderStateController.logStatus(TransferStateEnum.connection);
    if (_connectionClient.isConnected) {
      _senderStateController.logStatus(TransferStateEnum.connected);
      _senderStateController.logStatus(TransferStateEnum.generatingKey);
      final pair = AppCrypto.generateECKeyPair();
      _privateKey = pair.privateKey;
      _publicKey = pair.publicKey;

      _senderStateController.logStatus(TransferStateEnum.joining);
      _connectionClient.joinSession(
          _textEditingController.text.trim().toUpperCase(),
          AppCrypto.encodeECPublicKey(_publicKey!));
    } else {
      _senderStateController.logStatus(TransferStateEnum.connectionError);
    }
  }

  @override
  Future<void> onConnected() async {
    //
  }

  @override
  Future<void> onPublicKeyReceived(String publicKey) async {
    logMessage("PublicKey : $publicKey");
    _senderStateController.logStatus(TransferStateEnum.sharedKeyDeriving);
    final sharedKey = AppCrypto.deriveSharedSecret(
        _privateKey!, AppCrypto.decodeECPublicKey(publicKey));
    logMessage("Shared key derived [${sharedKey.length}] $sharedKey");
    _senderStateController.logStatus(TransferStateEnum.sharedKeyDerived);
    _senderStateController.logStatus(TransferStateEnum.waitingFile);
    _sharedKey = sharedKey;
    _sharedKeyDigest = hex.encode(AppCrypto.sha256Digest(_sharedKey!));

    _senderStateController.logStatus(TransferStateEnum.encryptionFile);
    final encrypted = await AppCrypto.encryptAESInIsolate(
        _selectedFile!.readAsBytesSync(), _sharedKey!);

    _senderStateController.logStatus(TransferStateEnum.writingEncryptedFile);
    final encFile = File(
        "${(await getApplicationCacheDirectory()).path}/enc_${FileUtils
            .fileName(_selectedFile!.path)}");
    encFile.writeAsBytesSync(encrypted);

    _senderStateController.logStatus(TransferStateEnum.generatingHmac);

    final hmac = hex.encode(await AppCrypto.generateHMACIsolate(_sharedKey!, encFile.readAsBytesSync()));

        _senderStateController.logStatus(TransferStateEnum.sendingFile);

      final sent = await _connectionClient.sendFile(
      encFile.path,
      FileUtils.fileName(_selectedFile!.path),
      _textEditingController.text.toUpperCase().trim(),
      hmac,
    );

    logMessage("Sent : $sent");
    _key.currentState?.snap
      (
    );
  }

  _clear() {
    _senderStateController.logStatus(TransferStateEnum.initial);
    _sharedKeyDigest = null;
    _textEditingController.clear();
    _publicKey = null;
    _privateKey = null;
    _fileBytes = [];
    _selectedFile = null;
    _key.currentState?.reset();
    setState(() {});
  }

  @override
  void dispose() {
    _connectionClient.disconnect();
    super.dispose();
  }
}
