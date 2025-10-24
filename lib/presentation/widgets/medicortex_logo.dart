import 'package:flutter/material.dart';

class MedicortexLogo extends StatelessWidget {
  final double size;

  const MedicortexLogo({
    super.key,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/medicortex_logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
