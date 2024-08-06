import 'app_localizations.dart';

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get send => 'Send file';

  @override
  String get receive => 'Receive receive';

  @override
  String get keyDerivationInfo => 'This text were derived from the encryption key';

  @override
  String get sourceCode => 'Source code';

  @override
  String get tapToCopy => 'Tap to copy';

  @override
  String get createSession => 'Create session';

  @override
  String get selectFile => 'Select file';

  @override
  String get inputSessionId => 'Input session ID';
}