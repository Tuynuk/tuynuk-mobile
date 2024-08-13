import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:safe_file_sender/ui/widgets/close_screen_button.dart';
import 'package:safe_file_sender/utils/file_utils.dart';

class TransmissionHistoryScreen extends StatefulWidget {
  const TransmissionHistoryScreen({super.key});

  @override
  State<TransmissionHistoryScreen> createState() =>
      _TransmissionHistoryScreenState();
}

class _TransmissionHistoryScreenState extends State<TransmissionHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const CloseScreenButton(),
      body: FutureBuilder(
        future: getApplicationDocumentsDirectory(),
        builder: (BuildContext context, AsyncSnapshot<Directory> snapshot) {
          if (!snapshot.hasData) return Container();
          final downloadsDir = Directory('${snapshot.data!.path}/downloads');
          if (!downloadsDir.existsSync()) {
            downloadsDir.createSync(recursive: true);
          }
          final files = Directory('${snapshot.data!.path}/downloads')
              .listSync()
              .map((e) => File(e.path))
              .toList();
          files.sort(
              (a, b) => b.lastAccessedSync().compareTo(a.lastAccessedSync()));

          return ListView.builder(
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              return InkWell(
                onTap: () {
                  //do smth
                },
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {
                        final isDeleted =
                            FileUtils.fromFileSystemEntity(file)?.safeDelete();
                        if (isDeleted == true) {
                          setState(() {});
                        }
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
                          FileUtils.fileName(file.path),
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
          );
        },
      ),
    );
  }
}
