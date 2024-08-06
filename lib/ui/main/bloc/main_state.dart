part of 'main_bloc.dart';

@immutable
class MainState {
  final Locale? locale;

  const MainState({this.locale});

  MainState copyWith({
    Locale? locale,
  }) {
    return MainState(
      locale: locale ?? this.locale,
    );
  }
}
