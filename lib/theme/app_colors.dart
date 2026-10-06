// lib/theme/app_colors.dart
import 'package:flutter/material.dart';

// Context-aware color helpers so screens don't hardcode the dark palette.
// The accent stays identical in both modes — it's the brand color, not a
// surface color, so it doesn't need to adapt to light/dark.
class AppColors {
  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color background(BuildContext context) =>
      _isDark(context) ? const Color(0xFF0D0D0D) : const Color(0xFFF5F5F7);

  static Color card(BuildContext context) =>
      _isDark(context) ? const Color(0xFF1A1A1A) : Colors.white;

  static Color textPrimary(BuildContext context) =>
      _isDark(context) ? Colors.white : const Color(0xFF1A1A1A);

  static Color textSecondary(BuildContext context) =>
      _isDark(context) ? Colors.white70 : Colors.black54;

  static Color textMuted(BuildContext context) =>
      _isDark(context) ? Colors.white54 : Colors.black45;

  static Color textFaint(BuildContext context) =>
      _isDark(context) ? Colors.white38 : Colors.black38;

  static Color divider(BuildContext context) =>
      _isDark(context) ? Colors.white24 : Colors.black12;

  // A barely-there tint for inactive chip/badge backgrounds — white-on-dark
  // reads as a faint highlight, but the same alpha of white is invisible on
  // a light card, so it needs to flip to a black tint instead.
  static Color subtleFill(BuildContext context) =>
      _isDark(context) ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04);

  static const accent = Color(0xFF00E676);
}
