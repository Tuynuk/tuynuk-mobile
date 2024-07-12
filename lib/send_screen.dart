import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pointycastle/ecc/api.dart';
import 'package:safe_file_sender/crypto/crypto.dart';
import 'package:safe_file_sender/dev/logger.dart';
import 'package:safe_file_sender/dialogs/send_bottom_sheet_dialog.dart';
import 'package:safe_file_sender/io/socket_client.dart';
import 'package:safe_file_sender/utils/file_utils.dart';
import 'package:safe_file_sender/widgets/button.dart';
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

    super.initState();
  }

  final TextEditingController _textEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          TextField(controller: _textEditingController),
          Button(
            onTap: () {
              _send();
            },
            child: const Icon(Icons.send),
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
                //
              },
              child: Container(
                height: 32,
                alignment: Alignment.center,
                margin: const EdgeInsets.all(24),
                child: _selectedFile == null
                    ? const Text(
                        "Select file",
                        style:
                            TextStyle(color: Colors.white, fontFamily: "Hack"),
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
        ],
      ),
    );
  }

  Future<void> _send() async {
    await _connectionClient.connect();

    final pair = AppCrypto.generateECKeyPair();
    _privateKey = pair.privateKey;
    _publicKey = pair.publicKey;

    _connectionClient.joinSession(
        _textEditingController.text, AppCrypto.encodeECPublicKey(_publicKey!));
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

    final encrypted =
        AppCrypto.encryptAES(_selectedFile!.readAsBytesSync(), _sharedKey!);
    final encFile = File(
        "${(await getApplicationCacheDirectory()).path}/enc_${FileUtils.fileName(_selectedFile!.path)}");
    encFile.writeAsBytesSync(encrypted);

    final sent = await _connectionClient.sendFile(
        encFile.path,
        FileUtils.fileName(_selectedFile!.path),
        _textEditingController.text.trim());
    logMessage("Sent : $sent");
    _clear();
  }

  _clear() {
    _publicKey = null;
    _privateKey = null;
    _fileBytes = [];
    _selectedFile = null;
  }
}
