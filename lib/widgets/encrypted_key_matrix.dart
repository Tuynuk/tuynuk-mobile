import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class EncryptionKeyWidget extends StatelessWidget {
  final List<String> keyMatrix;

  const EncryptionKeyWidget({super.key, required this.keyMatrix});

  Color _hexToColor(String hex) {
    int val = int.parse(hex, radix: 16);
    return Color.fromRGBO(
        (val >> 16) & 0xFF, (val >> 8) & 0xFF, val & 0xFF, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 8,
            mainAxisExtent: 12,
          ),
          itemCount: keyMatrix.length,
          itemBuilder: (context, index) {
            return Text(
              textAlign: TextAlign.center,
              keyMatrix[index].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12
              ),
            );
          },
        ),
        const Padding(
          padding: EdgeInsets.all(12),
        ),
        const Text(
          textAlign: TextAlign.center,
          "This text were derived from the encryption key",
          style: TextStyle(
            color: Colors.white30,
            fontFamily: "Hack",
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
