import 'app_localizations.dart';

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([super.locale = 'ru']);

  @override
  String get send => 'Отправить файл';

  @override
  String get receive => 'Получить файл';

  @override
  String get keyDerivationInfo => 'Этот текст был получен из ключа шифрования';

  @override
  String get sourceCode => 'Исходный код';

  @override
  String get tapToCopy => 'Нажмите, чтобы скопировать';

  @override
  String get createSession => 'Создать сессию';

  @override
  String get selectFile => 'Выбрать файл';

  @override
  String get inputSessionId => 'Введите ID сессии';

  @override
  String get appName => 'Tuynuk';

  @override
  String get language => 'Язык';
}
