import 'dart:ui';

import 'package:bloc/bloc.dart';
import 'package:encrypt_shared_preferences/provider.dart';
import 'package:meta/meta.dart';
import 'package:safe_file_sender/models/pref_keys.dart';

part 'main_event.dart';

part 'main_state.dart';

class MainBloc extends Bloc<MainEvent, MainState> {
  MainBloc() : super(const MainState()) {
    on<UpdateLocalization>(_updateLocale);
  }

  Future<void> _updateLocale(UpdateLocalization event, Emitter emitter) async {
    EncryptedSharedPreferences.getInstance()
        .setString(PrefKeys.localeCode, event.locale.languageCode);
    emitter(state.copyWith(locale: event.locale));
  }
}
