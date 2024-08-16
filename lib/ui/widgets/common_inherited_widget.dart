import 'package:encrypt_shared_preferences/provider.dart';
import 'package:flutter/material.dart';

class CommonInheritedWidget extends InheritedWidget {
  final EncryptedSharedPreferences _preferences;

  const CommonInheritedWidget(this._preferences,
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
      oldWidget._preferences != _preferences;
}

extension CommonInheritedWidgetExtensions on BuildContext {
  EncryptedSharedPreferences get preferences =>
      CommonInheritedWidget.of(this)._preferences;
}
