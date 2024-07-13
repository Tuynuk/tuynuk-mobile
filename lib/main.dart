import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:safe_file_sender/receive_screen.dart';
import 'package:safe_file_sender/send_screen.dart';
import 'package:safe_file_sender/widgets/scale_tap.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const SafeApp());
}

class SafeApp extends StatelessWidget {
  const SafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        "/send": (context) => const SendScreen(),
        "/receive": (context) => const ReceiveScreen(),
      },
      debugShowCheckedModeBanner: false,
      title: 'Tuynuk',
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

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
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
