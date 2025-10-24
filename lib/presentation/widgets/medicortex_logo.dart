import 'package:flutter/material.dart';

class MedicortexLogo extends StatelessWidget {
  final double size;

  const MedicortexLogo({
    super.key,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: MedicortexLogoPainter(),
    );
  }
}

class MedicortexLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Cyan/Teal
    paint.color = const Color.fromARGB(255, 66, 244, 208);
    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.height),
      -0.5 * 3.14159,
      0.75 * 3.14159,
      true,
      paint,
    );

    // Red
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.height),
      -0.5 * 3.14159,
      -0.5 * 3.14159,
      true,
      paint,
    );

    // Purple
    paint.color = const Color.fromARGB(255, 181, 5, 251);
    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.height),
      -1.0 * 3.14159,
      -0.5 * 3.14159,
      true,
      paint,
    );

    // Green
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.height),
      0.25 * 3.14159,
      0.75 * 3.14159,
      true,
      paint,
    );

    // White center
    paint.color = Colors.white;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 3,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
