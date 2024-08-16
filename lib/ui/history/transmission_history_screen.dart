import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:safe_file_sender/cache/preferences_cache_keys.dart';
import 'package:safe_file_sender/crypto/crypto_core.dart';
import 'package:safe_file_sender/dev/logger.dart';
import 'package:safe_file_sender/ui/widgets/close_screen_button.dart';
import 'package:safe_file_sender/ui/widgets/common_inherited_widget.dart';
import 'package:safe_file_sender/utils/file_utils.dart';
import 'package:share_plus/share_plus.dart';

class TransmissionHistoryScreen extends StatefulWidget {
  const TransmissionHistoryScreen({super.key});

  @override
  State<TransmissionHistoryScreen> createState() =>
      _TransmissionHistoryScreenState();
}

class _TransmissionHistoryScreenState extends State<TransmissionHistoryScreen> {
  List<FileSystemEntity> _files = [];

  @override
  void initState() {
    _loadFiles();
    super.initState();
  }

  _loadFiles() async {
    final directory = Directory(
        '${(await getApplicationDocumentsDirectory()).path}/downloads');
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }
    _files = directory
        .listSync()
        .map((e) => File(e.path))
        .where((e) => !FileSystemEntity.isDirectorySync(e.path))
        .toList();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const CloseScreenButton(),
      body: ListView.builder(
        itemCount: _files.length,
        itemBuilder: (context, index) {
          final file = _files[index];
          final fileName = FileUtils.fileName(file.path);
          return InkWell(
            onTap: () async {
              final decrypted = File(
                  '${(await getApplicationDocumentsDirectory()).path}/downloads/temp/$fileName');
              await decrypted.create(recursive: true);

              if (context.mounted) {
                AppCrypto.fileEncryptionService(context.preferences
                        .getString(PreferencesCacheKeys.pin)!)
                    .decryptFile(file.path, decrypted.path)
                    .then((value) {
                  Share.shareXFiles([XFile(decrypted.path)])
                      .then((value) async {
                    logMessage('Sharing end');
                    FileUtils.clearDecryptedCache();
                  });
                });
              }
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    final isDeleted =
                        FileUtils.fromFileSystemEntity(file)?.safeDelete();
                    setState(() {});
                  },
                  icon: const Icon(
                    Icons.delete,
                    color: Colors.redAccent,
                  ),
                ),
                Flexible(
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    child: Text(
                      fileName,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontSize: 10),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    FileUtils.clearDecryptedCache();
    super.dispose();
  }
}
