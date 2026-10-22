import 'package:flutter/material.dart';

class AppColors {
  // 60% — Background
  static const Color background = Color(0xFF09090B);

  // 30% — Surface
  static const Color surface = Color(0xFF18181B);
  static const Color surfaceElevated = Color(0xFF27272A);

  // 10% — Accent
  static const Color accent = Color(0xFF6366F1);
  static const Color accentMuted = Color(0xFF4F46E5);

  // Borders
  static const Color border = Color(0xFF27272A);
  static const Color borderSubtle = Color(0xFF3F3F46);

  // Emergency / Danger
  static const Color emergency = Color(0xFFEF4444);
  static const Color emergencyBg = Color(0xFF1C1017);
  static const Color emergencyBorder = Color(0xFF7F1D1D);

  // Safe / Success
  static const Color safe = Color(0xFF22C55E);
  static const Color safeBg = Color(0xFF0C1A12);
  static const Color safeBorder = Color(0xFF166534);

  // Warning
  static const Color warning = Color(0xFFF59E0B);

  // Primary (alias to accent for backward compatibility)
  static const Color primary = accent;

  // Typography
  static const Color textPrimary = Color(0xFFFAFAFA);
  static const Color textSecondary = Color(0xFFA1A1AA);
  static const Color textMuted = Color(0xFF71717A);
}
