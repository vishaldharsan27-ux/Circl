// lib/widgets/connect_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class ConnectBottomSheet extends StatelessWidget {
  final String name;

  const ConnectBottomSheet({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Color(0xFF00E676),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.black, size: 40),
          ).animate().scale(
                duration: 500.ms,
                curve: Curves.elasticOut,
                begin: const Offset(0.0, 0.0),
                end: const Offset(1.0, 1.0),
              ),
          const SizedBox(height: 24),
          Text(
            'Connection Sent! 🎉',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "We'll notify $name that you want to connect",
            style: GoogleFonts.poppins(color: AppColors.textMuted(context)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back to Discover'),
            ),
          ),
        ],
      ),
    );
  }
}
