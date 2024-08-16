import 'package:encrypt_shared_preferences/provider.dart';
import 'package:flutter/material.dart';
import 'package:safe_file_sender/common/app_temp_data.dart';

class CommonInheritedWidget extends InheritedWidget {
  final EncryptedSharedPreferences _preferences;
  final AppTempData _appTempData;

  const CommonInheritedWidget(this._preferences, this._appTempData,
      {super.key, required super.child});

  static CommonInheritedWidget? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<CommonInheritedWidget>();
  }

  static CommonInheritedWidget of(BuildContext context) {
    final CommonInheritedWidget? result = maybeOf(context);
    assert(result != null, 'No CommonInheritedWidget found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(covariant CommonInheritedWidget oldWidget) =>
      oldWidget._preferences != _preferences ||
      oldWidget._appTempData != _appTempData;
}

extension CommonInheritedWidgetExtensions on BuildContext {
  EncryptedSharedPreferences get preferences => CommonInheritedWidget.of(this)._preferences;
  AppTempData get appTempData => CommonInheritedWidget.of(this)._appTempData;
}
