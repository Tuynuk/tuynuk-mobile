import 'package:flutter/material.dart';

class CloseScreenButton extends StatelessWidget {
  const CloseScreenButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          alignment: Alignment.center,
          width: 42,
          height: 42,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12), color: Colors.white12),
          margin: const EdgeInsets.all(24),
          child: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.close,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
