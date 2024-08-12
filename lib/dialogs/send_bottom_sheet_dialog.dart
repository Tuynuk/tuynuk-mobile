import 'package:flutter/material.dart';

class SendBottomSheetDialog {
  static bool _isVisible = false;

  static Future<void> show(
      BuildContext context, Function(String identifier) onIdentifierInput,
      {required Function() onClose}) async {
    final TextEditingController textEditingController = TextEditingController();
    _isVisible = true;
    showModalBottomSheet(
      backgroundColor: Colors.black,
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.deepPurple,
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(24),
          height: 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: textEditingController,
                ),
                TextButton(
                  onPressed: () {
                    onIdentifierInput.call(textEditingController.text.trim());
                    Navigator.pop(context);
                  },
                  child: const Text('Connect'),
                ),
              ],
            ),
          ),
        );
      },
    ).then((value) {
      _isVisible = false;
      onClose.call();
    });
  }

  static hide(BuildContext context) {
    Navigator.pop(context);
    _isVisible = false;
  }
}
