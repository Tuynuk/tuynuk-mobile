import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pointycastle/ecc/api.dart';
import 'package:pointycastle/impl.dart';
import 'package:safe_file_sender/crypto/crypto.dart';
import 'package:safe_file_sender/dev/logger.dart';
import 'package:safe_file_sender/io/socket_client.dart';
import 'package:safe_file_sender/dialogs/receive_bottom_sheet_dialog.dart';
import 'package:safe_file_sender/models/user_state_enum.dart';
import 'package:safe_file_sender/widgets/button.dart';
import 'package:safe_file_sender/widgets/scale_tap.dart';
import 'package:safe_file_sender/dialogs/send_bottom_sheet_dialog.dart';
import 'package:safe_file_sender/widgets/snap_effect.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const SafeApp());
}

class SafeApp extends StatelessWidget {
  const SafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: false,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> implements EventListeners {
  final GlobalKey<SnappableState> _key = GlobalKey();
  File? _selectedFile;

  List<int> _fileBytes = [];

  late ConnectionClient _connectionClient;

  @override
  void initState() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _connectionClient = ConnectionClient(this);
    super.initState();
  }

  ECPrivateKey? _privateKey;
  ECPublicKey? _publicKey;
  Uint8List? _sharedKey;
  UserStateEnum? _userStateEnum;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Button(
                  onTap: () async {
                    _send();
                  },
                  child: const Icon(
                    Icons.upload,
                    color: Colors.white,
                  ),
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
                Button(
                  onTap: () async {
                    _receive();
                  },
                  child: const Icon(
                    Icons.download,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: ScaleTap(
              onPressed: () {
                launchUrl(Uri.parse("https://github.com/xaldarof/safe_file"),
                    mode: LaunchMode.externalApplication);
              },
              child: Container(
                margin: const EdgeInsets.all(12),
                child: const Text(
                  "Source code",
                  style: TextStyle(
                      fontFamily: "Hack", color: Colors.white60, fontSize: 8),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Future<void> _send() async {
    await _connectionClient.connect();

    _userStateEnum == UserStateEnum.sender;
    _userStateEnum = UserStateEnum.sender;
    final pair = AppCrypto.generateRSAKeyPair();
    _privateKey = pair.privateKey;
    _publicKey = pair.publicKey;
    if (!context.mounted) return;
    SendBottomSheetDialog.show(
      context,
      (identifier) {
        logMessage("Joining : $identifier");
        _connectionClient.joinSession(
            identifier, AppCrypto.encodeECPublicKey(_publicKey!));
      },
      onClose: () async {
        //
      },
    ).then((value) {});
  }

  Future<void> _receive() async {
    await _connectionClient.connect();

    if (!context.mounted) return;
    ReceiveBottomSheetDialog.show(context, onClose: () async {
      // await _connectionClient.disconnect();
    });
    // await _connectionClient.connect();

    _userStateEnum = UserStateEnum.receiver;

    if (_connectionClient.isConnected) {
      final keyPair = AppCrypto.generateRSAKeyPair();
      _publicKey = keyPair.publicKey;
      _privateKey = keyPair.privateKey;
      _connectionClient
          .createSession(AppCrypto.encodeECPublicKey(keyPair.publicKey));
    }
  }

  @override
  Future<void> onPublicKeyReceived(String publicKey) async {
    logMessage("PublicKey : $publicKey");
    final sharedKey = AppCrypto.deriveSharedSecret(
        _privateKey!, AppCrypto.decodeECPublicKey(publicKey));
    logMessage("Shared key derived [${sharedKey.length}] $sharedKey");
    _sharedKey = sharedKey;

    if (_userStateEnum == UserStateEnum.sender) {
      final encrypted =
          AppCrypto.encryptAES(_selectedFile!.readAsBytesSync(), _sharedKey!);
      _connectionClient.sendFile(base64Encode(encrypted), "fileName");
    }
  }

  @override
  Future<void> onIdentifierReceived(String publicKey) async {
    // ReceiveBottomSheetDialog.hide(context);
  }

  @override
  Future<void> onConnected() async {
    //
  }

  @override
  Future<void> onFileReceived(String content) async {
    final decBytes = AppCrypto.decryptAES(base64Decode(content), _sharedKey!);
    final file = File("file.exp");
    file.writeAsBytesSync(decBytes);

    if (_userStateEnum == UserStateEnum.receiver) {
      _clear();
      await _connectionClient.disconnect();
    }
  }

  _clear() {
    _publicKey = null;
    _privateKey = null;
    _userStateEnum = null;
    _fileBytes = [];
    _selectedFile = null;
  }
}
