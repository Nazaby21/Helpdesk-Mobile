import 'package:flutter/material.dart';

/// Typography configuration mapping the Satoshi type scale from 06-design-system.md
abstract final class AppTypography {
  static const String fontFamily = 'Satoshi';

  // Font weights
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight black = FontWeight.w900;

  // Web type scale equivalents
  // text-heading-5: 28px / 40px -> headlineMedium: 28sp, w700
  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    height: 40 / 28,
    fontWeight: bold,
    letterSpacing: -0.2,
  );

  // text-heading-6: 24px / 30px -> headlineSmall: 24sp, w700
  static const TextStyle headlineSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    height: 30 / 24,
    fontWeight: bold,
    letterSpacing: -0.2,
  );

  // text-body-2xlg: 22px / 28px -> titleLarge: 22sp, w600
  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    height: 28 / 22,
    fontWeight: semiBold,
  );

  // titleMedium: 18sp, w600
  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    height: 24 / 18,
    fontWeight: semiBold,
  );

  // text-base: 16px / 24px -> bodyLarge: 16sp, w500
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: medium,
  );

  // text-sm / body-sm: 14px / 22px -> bodyMedium: 14sp, w400
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 22 / 14,
    fontWeight: regular,
  );

  // labelMedium: 13sp, w500
  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    height: 18 / 13,
    fontWeight: medium,
  );

  // text-xs / body-xs: 12px / 20px -> bodySmall: 12sp, w400
  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 18 / 12,
    fontWeight: regular,
  );

  // text-xs / body-xs: 12px / 20px -> labelSmall: 12sp, w500
  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 20 / 12,
    fontWeight: medium,
  );
}
