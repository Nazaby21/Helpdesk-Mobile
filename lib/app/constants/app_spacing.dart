import 'package:flutter/material.dart';

/// Spacing, radii, and shadow tokens according to 06-design-system.md
abstract final class AppSpacing {
  // Spacing scales
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double huge = 40.0;
  static const double massive = 48.0;

  // Border Radii
  static const double radiusSm = 6.0;
  static const double radiusLg = 8.0;     // rounded-lg: Buttons, Text Inputs, Badges
  static const double radiusInput = 10.0; // Input rounded corners (Section 2.3)
  static const double radiusXl = 12.0;    // rounded-xl: Cards, Toasts, Dialogs
  static const double radius2Xl = 16.0;   // rounded-2xl: Catalog Cards, Sign-in Card
  static const double radiusFull = 9999.0;// rounded-full: Pill badges, Avatars

  static final BorderRadius borderRadiusSm = BorderRadius.circular(radiusSm);
  static final BorderRadius borderRadiusMd = BorderRadius.circular(radiusLg);
  static final BorderRadius borderRadiusLg = BorderRadius.circular(radiusLg);
  static final BorderRadius borderRadiusInput = BorderRadius.circular(radiusInput);
  static final BorderRadius borderRadiusXl = BorderRadius.circular(radiusXl);
  static final BorderRadius borderRadius2Xl = BorderRadius.circular(radius2Xl);
  static final BorderRadius borderRadiusFull = BorderRadius.circular(radiusFull);

  // Box Shadows
  // shadow-1: BoxShadow(color: Color(0x1F545776), blurRadius: 2, offset: Offset(0, 1))
  static const BoxShadow shadow1 = BoxShadow(
    color: Color(0x1F545776),
    blurRadius: 2,
    offset: Offset(0, 1),
  );

  static const BoxShadow shadowSm = shadow1;

  // shadow-md: BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 4))
  static const BoxShadow shadowMd = BoxShadow(
    color: Color(0x14000000),
    blurRadius: 6,
    offset: Offset(0, 4),
  );
}
