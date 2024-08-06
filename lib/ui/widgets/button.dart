import 'package:flutter/material.dart';
import 'package:safe_file_sender/ui/widgets/scale_tap.dart';

class Button extends StatelessWidget {
  final Function() onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onPressed: () async {
        onTap.call();
      },
      child: Container(
        width: 52,
        decoration: BoxDecoration(
          color: Colors.deepPurple,
          borderRadius: BorderRadius.circular(12),
        ),
        height: 52,
        child: child,
      ),
    );
  }

  const Button({
    super.key,
    required this.onTap,
    required this.child,
  });
}
