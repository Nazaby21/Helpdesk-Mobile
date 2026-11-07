import 'package:flutter/material.dart';

/// Design tokens derived from tailwind.config.ts and 06-design-system.md
abstract final class AppColors {
  // Brand & Primary
  static const Color primary = Color(0xFF5750F1);
  static const Color primaryHover = Color(0xFF4338CA);
  static const Color chartCyan = Color(0xFF0ABEF9);

  // Light Mode Neutrals
  static const Color lightScaffold = Color(0xFFF3F4F6); // gray-2
  static const Color lightBackground = lightScaffold;
  static const Color lightCard = Color(0xFFFFFFFF);     // white
  static const Color lightInput = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE6EBF1);   // stroke
  static const Color lightBorderInput = Color(0xFFD1D5DB); // input stroke
  static const Color lightTextPrimary = Color(0xFF111928); // dark
  static const Color lightTextSecondary = Color(0xFF4B5563); // dark-4
  static const Color lightTextMuted = Color(0xFF9CA3AF);     // dark-6

  // Dark Mode Neutrals
  static const Color darkScaffold = Color(0xFF020D1A);
  static const Color darkBackground = darkScaffold;
  static const Color darkCard = Color(0xFF122031);     // gray-dark
  static const Color darkInput = Color(0xFF1F2A37);    // dark-2
  static const Color darkBorder = Color(0xFF27303E);   // stroke-dark
  static const Color darkBorderInput = Color(0xFF374151);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFF9CA3AF); // dark-6
  static const Color darkTextMuted = Color(0xFF6B7280);     // dark-5

  // Semantic & Feedback (Main)
  static const Color success = Color(0xFF22AD5C);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFF23030);
  static const Color errorInput = Color(0xFFEF4444);
  static const Color info = Color(0xFF3C50E0);
  static const Color orangeAccent = Color(0xFFF59460);
  static const Color mediumPriority = orangeAccent;

  // Semantic Backgrounds (Light mode badges/alerts)
  static const Color successBg = Color(0xFFE9FBF0); // green-light-7
  static const Color successLight = successBg;
  static const Color warningBg = Color(0xFFFFFBEB); // yellow-light-4
  static const Color warningLight = warningBg;
  static const Color errorBg = Color(0xFFFEF3F3);   // red-light-6
  static const Color errorLight = errorBg;
  static const Color infoBg = Color(0xFFE1E8FF);    // blue-light-5
  static const Color infoLight = infoBg;
  static const Color orangeBg = Color(0xFFFFF7ED);  // orange-light
  static const Color mediumPriorityLight = orangeBg;
  static const Color defaultBadgeBg = Color(0xFFF3F4F6);
  static const Color defaultBadgeText = Color(0xFF374151);

  // Button Secondary / Outline
  static const Color buttonSecondaryBg = Color(0xFFF3F4F6);
  static const Color buttonSecondaryText = Color(0xFF111928);
  static const Color buttonOutlineBorder = Color(0xFFD1D5DB);
  static const Color buttonOutlineText = Color(0xFF374151);
  static const Color buttonDangerBg = Color(0xFFDC2626);
}
