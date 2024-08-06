import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:safe_file_sender/dev/logger.dart';
import 'package:safe_file_sender/receive_screen.dart';
import 'package:safe_file_sender/send_screen.dart';
import 'package:safe_file_sender/widgets/scale_tap.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  runApp(const SafeApp());
}

class SafeApp extends StatelessWidget {
  const SafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        "/send": (context) => SendScreen(
            sharedFile:
                ModalRoute.of(context)?.settings.arguments as SharedMediaFile?),
        "/receive": (context) => const ReceiveScreen(),
      },
      debugShowCheckedModeBanner: false,
      title: 'Tuynuk',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: false,
      ),
      home: const TuynukHomePage(title: 'Tuynuk'),
    );
  }
}

class TuynukHomePage extends StatefulWidget {
  const TuynukHomePage({super.key, required this.title});

  final String title;

  @override
  State<TuynukHomePage> createState() => _TuynukHomePageState();
}

class _TuynukHomePageState extends State<TuynukHomePage> {
  late StreamSubscription _sharingIntentSubscription;

  @override
  void initState() {
    _handleSharingIntent();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initQuickActions();
    super.initState();
  }

  _handleAction(String actionType) {
    if (actionType == 'send') {
      Navigator.pushNamed(context, "/send");
    }
    if (actionType == 'receive') {
      Navigator.pushNamed(context, "/receive");
    }
  }

  _initQuickActions() {
    const QuickActions quickActions = QuickActions();
    quickActions.initialize((String shortcutType) {
      _handleAction(shortcutType);
    });

    quickActions.setShortcutItems(<ShortcutItem>[
      const ShortcutItem(
          type: 'receive',
          localizedTitle: 'Receive',
          icon: 'round_arrow_downward_24'),
      const ShortcutItem(
          type: 'send',
          localizedTitle: 'Send',
          icon: 'baseline_arrow_upward_24'),
    ]);
  }

  @override
  void dispose() {
    _sharingIntentSubscription.cancel();
    super.dispose();
  }

  Future<void> _handleSharingIntent() async {
    try {
      if (!(Platform.isAndroid || Platform.isIOS)) return;
      _sharingIntentSubscription =
          ReceiveSharingIntent.instance.getMediaStream().listen((value) {
        if (!Navigator.canPop(context) && value.isNotEmpty) {
          Navigator.pushNamed(context, "/send", arguments: value.first);
          ReceiveSharingIntent.instance.reset();
        }
        logMessage(value.map((f) => f.toMap()));
      }, onError: (err) {
        logMessage(err);
      });
      ReceiveSharingIntent.instance.getInitialMedia().then((value) {
        if (value.isNotEmpty) {
          Navigator.pushNamed(context, "/send", arguments: value.first);
          ReceiveSharingIntent.instance.reset();
        }
      });
    } catch (e) {
      // Handle exceptions
    }
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
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, "/send");
                  },
                  child: const Text(
                    "Send file",
                    style: TextStyle(fontFamily: "Hack"),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, "/receive");
                  },
                  child: const Text(
                    "Receive file",
                    style: TextStyle(fontFamily: "Hack"),
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
}
