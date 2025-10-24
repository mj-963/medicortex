import 'package:flutter/material.dart';

class MedicalDisclaimerBanner extends StatefulWidget {
  const MedicalDisclaimerBanner({super.key});

  @override
  State<MedicalDisclaimerBanner> createState() =>
      _MedicalDisclaimerBannerState();
}

class _MedicalDisclaimerBannerState extends State<MedicalDisclaimerBanner> {
  bool _isDismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_isDismissed) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7), // Amber/Yellow background
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFD97706),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '⚠️ Medical Disclaimer',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This information is for educational purposes only. Always consult a qualified healthcare professional for medical advice.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[800],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () {
              setState(() => _isDismissed = true);
            },
            color: const Color(0xFF92400E),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
