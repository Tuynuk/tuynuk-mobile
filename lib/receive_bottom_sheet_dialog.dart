import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ReceiveBottomSheetDialog {
  static bool _isVisible = false;

  static Future<void> show(BuildContext context) async {
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
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: Colors.white,
                ),
                Padding(padding: EdgeInsets.all(12)),
                Text(
                  "Waiting for file...",
                  style: TextStyle(color: Colors.white, fontFamily: "Raleway"),
                )
              ],
            ),
          ),
        );
      },
    ).then((value) {
      _isVisible = false;
    });
  }

  static hide(BuildContext context) {
    Navigator.pop(context);
    _isVisible = false;
  }
}
