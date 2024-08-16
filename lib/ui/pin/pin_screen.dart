import 'package:encrypt_shared_preferences/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safe_file_sender/crypto/crypto_core.dart';
import 'package:safe_file_sender/dev/logger.dart';
import 'package:safe_file_sender/utils/navigator_utils.dart';
import 'package:safe_file_sender/cache/preferences_cache_keys.dart';
import 'package:safe_file_sender/models/path_values.dart';
import 'package:safe_file_sender/ui/widgets/common_inherited_widget.dart';
import 'package:safe_file_sender/utils/context_utils.dart';

class PinScreen extends StatefulWidget {
  PinScreen({super.key});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final TextEditingController _textEditingController = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Align(
            alignment: Alignment.center,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.all(32),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: context.localization.inputPin,
                    ),
                    controller: _textEditingController,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(right: 32),
                  child: TextButton(
                    onPressed: () {
                      _handleTap(context);
                    },
                    child: _loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(),
                          )
                        : context.preferences
                                    .getString(PreferencesCacheKeys.pin) !=
                                null
                            ? Text(context.localization.done)
                            : Text(context.localization.setupPin),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool checkValidPin(BuildContext context) {
    return context.preferences.getString(PreferencesCacheKeys.pin) ==
        _textEditingController.text.trim();
  }

  void _handleTap(BuildContext context) {
    bool hasPin =
        context.preferences.getString(PreferencesCacheKeys.pin) != null;
    if (hasPin) {
      if (checkValidPin(context)) {
        _goHome(context);
      } else {
        logMessage('Fuu!');
      }
    } else {
      context.preferences
          .setString(
              PreferencesCacheKeys.pin, _textEditingController.text.trim())
          .then((value) {});
      _goHome(context);
    }
  }

  _goHome(BuildContext context) async {
    setState(() {
      _loading = true;
    });
    final key =
        await AppCrypto.deriveKeyIsolate(_textEditingController.text.trim());
    setState(() {
      _loading = false;
    });
    if (context.mounted) {
      logMessage('Key derived : $key');
      context.appTempData.setPinDerivedKey(key);
      Navigator.pushNamedAndRemoveUntil(
          context, PathValues.home, NavigatorRoutePredicates.deleteAll);
    }
  }
}