import 'app_localizations.dart';

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get send => 'Отправить';

  @override
  String get receive => 'Получить';

  @override
  String get keyDerivationInfo => 'Этот текст был получен из ключа шифрования';
}
