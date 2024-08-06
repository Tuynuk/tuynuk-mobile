import 'dart:async';
import 'dart:io';

import 'package:encrypt_shared_preferences/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:safe_file_sender/dev/logger.dart';
import 'package:safe_file_sender/l10n/gen/app_localizations.dart';
import 'package:safe_file_sender/ui/main/bloc/main_bloc.dart';
import 'package:safe_file_sender/ui/receive_screen.dart';
import 'package:safe_file_sender/ui/send_screen.dart';
import 'package:safe_file_sender/ui/widgets/scale_tap.dart';
import 'package:safe_file_sender/utils/context_utils.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  EncryptedSharedPreferences.initialize("");
  runApp(
    SafeApp(
      locale: EncryptedSharedPreferences.getInstance().getString('localeCode'),
    ),
  );
}

class SafeApp extends StatelessWidget {
  final String? locale;

  const SafeApp({super.key, this.locale});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MainBloc(),
      child: BlocConsumer<MainBloc, MainState>(
        builder: (context, state) {
          return MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routes: {
              "/send": (context) => SendScreen(
                  sharedFile: ModalRoute.of(context)?.settings.arguments
                      as SharedMediaFile?),
              "/receive": (context) => const ReceiveScreen(),
            },
            locale: Locale(EncryptedSharedPreferences.getInstance()
                .getString('localeCode', defaultValue: "en")!),
            debugShowCheckedModeBanner: false,
            title: 'Tuynuk',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useMaterial3: false,
            ),
            home: const TuynukHomePage(title: 'Tuynuk'),
          );
        },
        listener: (context, state) {
          //
        },
      ),
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
            alignment: Alignment.topRight,
            child: DropdownButton<Locale>(
              underline: null,
              icon: null,
              hint: Text(
                context.localization.inputSessionId,
                style: const TextStyle(color: Colors.white),
              ),
              onChanged: (Locale? locale) {
                if (locale == null) return;
                context.read<MainBloc>().add(UpdateLocalization(locale));
              },
              items: const [
                DropdownMenuItem(
                  value: Locale('en', ''),
                  child: Text('English'),
                ),
                DropdownMenuItem(
                  value: Locale('ru', ''),
                  child: Text('Русский'),
                ),
                DropdownMenuItem(
                  value: Locale('uz', ''),
                  child: Text('O‘zbekcha'),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, "/send");
                  },
                  child: Text(
                    context.localization.send,
                    style: const TextStyle(fontFamily: "Hack"),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, "/receive");
                  },
                  child: Text(
                    context.localization.receive,
                    style: const TextStyle(fontFamily: "Hack"),
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
                child: Text(
                  context.localization.sourceCode,
                  style: const TextStyle(
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
