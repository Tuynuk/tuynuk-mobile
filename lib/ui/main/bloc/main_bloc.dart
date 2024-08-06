import 'dart:ui';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'main_event.dart';

part 'main_state.dart';

class MainBloc extends Bloc<MainEvent, MainState> {
  MainBloc() : super(const MainState()) {
    on<UpdateLocalization>(_updateLocale);
  }

  Future<void> _updateLocale(UpdateLocalization event, Emitter emitter) async {
    emitter(state.copyWith(locale: event.locale));
  }
}
