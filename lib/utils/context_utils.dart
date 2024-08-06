import 'package:flutter/widgets.dart';
import 'package:safe_file_sender/l10n/gen/app_localizations.dart';

extension ContextExt on BuildContext {
  AppLocalizations get localization => AppLocalizations.of(this);
}
