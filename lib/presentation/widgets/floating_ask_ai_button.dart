import 'package:flutter/material.dart';

class FloatingAskAiButton extends StatefulWidget {
  final String selectedText;
  final Offset position;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const FloatingAskAiButton({
    super.key,
    required this.selectedText,
    required this.position,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<FloatingAskAiButton> createState() => _FloatingAskAiButtonState();
}

class _FloatingAskAiButtonState extends State<FloatingAskAiButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.position.dx,
      top: widget.position.dy,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(24),
            color: const Color(0xFF2563EB),
            child: InkWell(
              onTap: () {
                widget.onTap();
                widget.onDismiss();
              },
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.psychology,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Ask AI about this',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '✨',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
