import 'package:flutter/material.dart';

void main() {
  runApp(const GoogleHomeClone());
}

class GoogleHomeClone extends StatelessWidget {
  const GoogleHomeClone({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const GoogleHomePage(),
      theme: ThemeData(fontFamily: 'Roboto'),
    );
  }
}

final GlobalKey _textFieldKey = GlobalKey();

class GoogleHomePage extends StatefulWidget {
  const GoogleHomePage({super.key});

  @override
  State<GoogleHomePage> createState() => _GoogleHomePageState();
}

class _GoogleHomePageState extends State<GoogleHomePage> {
  TextEditingController get _searchController =>
      TextEditingController(text: '');

  double getBorderRadius() {
    final RenderBox? renderBox =
        _textFieldKey.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox == null) return 50.0; // Default for initial render

    final currentHeight = renderBox.size.height;

    // Estimate single line height based on text style
    final textStyle =
        Theme.of(context).textTheme.bodyLarge ?? const TextStyle(fontSize: 16);
    final singleLineHeight =
        textStyle.fontSize! * 1.5; // 1.5 is typical line height multiplier

    const double maxRadius = 50.0;
    const double minRadius = 20.0;
    double maxHeight = singleLineHeight * 5;

    final ratio =
        (currentHeight - singleLineHeight) / (maxHeight - singleLineHeight);
    final radius = maxRadius - (ratio * (maxRadius - minRadius));

    return radius.clamp(minRadius, maxRadius);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      body: Stack(
        children: [
          // Centered Search and Icons
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Google Search Bar
                Container(
                  constraints: const BoxConstraints(maxWidth: 584),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(getBorderRadius()),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      CustomPaint(
                        size: const Size(24, 24),
                        painter: MedicortexLogoPainter(),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          key: _textFieldKey,
                          controller: _searchController,
                          minLines: 1,
                          maxLines: 5,

                          decoration: InputDecoration(
                            hintText: "What do you want to research today?",
                            hintStyle: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_upward, color: Colors.blueAccent),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildActionButton(Icons.add, 'Add'),
                    const SizedBox(width: 24),
                    _buildActionButton(Icons.bookmark_border, 'Bookmarks'),
                    const SizedBox(width: 24),
                  ],
                ),
              ],
            ),
          ),

          // Top-right profile and menu icons
          Positioned(
            top: 30,
            right: 30,
            child: Row(
              children: [
                const SizedBox(width: 15),
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xFFDFE3EB),
                  child: Icon(Icons.settings, color: Colors.blueAccent),
                ),
              ],
            ),
          ),

          // Top-left language
          const Positioned(top: 30, left: 30, child: _LanguageSelector()),

          // Bottom-right info and settings
          Positioned(
            bottom: 20,
            right: 30,
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 20),
                Icon(Icons.link, size: 20, color: Colors.grey[600]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Circle button widget
  Widget _buildActionButton(IconData icon, String label) {
    return Tooltip(
      message: label,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFFDCDEE1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 24, color: const Color(0xFF5F6368)),
      ),
    );
  }
}

// Language Selector widget
class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: .05), blurRadius: 4),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomPaint(
            size: const Size(24, 24),
            painter: MedicortexLogoPainter(),
          ),
          const SizedBox(width: 8),
          const Text("Medicortex", style: TextStyle(color: Colors.black87)),
        ],
      ),
    );
  }
}

class MedicortexLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Blue
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

    // Yellow
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
