import 'package:flutter/material.dart';
import 'package:safe_file_sender/utils/context_utils.dart';

class EncryptionKeyWidget extends StatelessWidget {
  final List<String> keyMatrix;

  const EncryptionKeyWidget({super.key, required this.keyMatrix});

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
              style: const TextStyle(color: Colors.white, fontSize: 12),
            );
          },
        ),
        const Padding(
          padding: EdgeInsets.all(12),
        ),
        Text(
          textAlign: TextAlign.center,
          context.localization.keyDerivationInfo,
          style: const TextStyle(
            color: Colors.white30,
            fontFamily: "Hack",
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
