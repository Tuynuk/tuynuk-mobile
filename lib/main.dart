import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:safe_file_sender/io/socket_client.dart';
import 'package:safe_file_sender/receive_bottom_sheet_dialog.dart';
import 'package:safe_file_sender/scale_tap.dart';
import 'package:safe_file_sender/snap_effect.dart';
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

  late SocketClient _socketClient;

  @override
  void initState() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _socketClient = SocketClient(this);
    super.initState();
  }

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
                ScaleTap(
                  onPressed: () async {
                    _key.currentState?.snap();
                  },
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.deepPurple,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.upload,
                      color: Colors.white,
                    ),
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
                ScaleTap(
                  onPressed: () {
                    ReceiveBottomSheetDialog.show(context);
                    _selectedFile = null;
                    _fileBytes = [];
                    _key.currentState?.reset();
                    setState(() {});
                  },
                  child: Container(
                    width: 52,
                    decoration: BoxDecoration(
                      color: Colors.deepPurple,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    height: 52,
                    child: const Icon(
                      Icons.download,
                      color: Colors.white,
                    ),
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

  @override
  void onPublicKeyReceived(String publicKey) async {
    //
  }
}
