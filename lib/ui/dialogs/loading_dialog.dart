import 'package:flutter/material.dart';

class LoadingDialog {
  static bool _isLoading = false;

  static void showLoadingDialog(BuildContext context,
      {bool barrierDismissible = false}) {
    _isLoading = true;
    showDialog(
      context: context,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
      barrierDismissible: barrierDismissible,
    ).then((value) {
      _isLoading = false;
    });
  }

  static void hideLoadingDialog(BuildContext context) {
    if (_isLoading) {
      Navigator.pop(context);
      _isLoading = false;
    }
  }
}
