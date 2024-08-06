part of 'main_bloc.dart';

@immutable
sealed class MainEvent {}

class UpdateLocalization extends MainEvent {
  final Locale locale;

  UpdateLocalization(this.locale);
}
