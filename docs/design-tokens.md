# Design Tokens & UI Foundations

These design tokens are mapped 1:1 from the web frontend Tailwind configuration ([tailwind.config.ts](file:///D:/Course%20Wing/Final/fix/helpdesk-frontend/tailwind.config.ts)) and global stylesheet ([style.css](file:///D:/Course%20Wing/Final/fix/helpdesk-frontend/src/css/style.css)).

---

## 1. Color Palette

### 1.1 Brand & Accent Colors
```dart
abstract final class AppColors {
  // Brand
  static const Color primary = Color(0xFF5750F1); // Indigo Primary
  static const Color primaryHover = Color(0xFF4338CA); // Deep Indigo
  static const Color chartCyan = Color(0xFF0ABEF9); // Cyan Analytics Line

  // Light Mode Surfaces
  static const Color lightBackground = Color(0xFFF3F4F6); // Gray-2
  static const Color lightCard = Color(0xFFFFFFFF); // Pure White
  static const Color lightInput = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE6EBF1); // Stroke
  static const Color lightTextPrimary = Color(0xFF111928); // Dark
  static const Color lightTextSecondary = Color(0xFF4B5563); // Dark-4
  static const Color lightTextMuted = Color(0xFF9CA3AF); // Dark-6

  // Dark Mode Surfaces
  static const Color darkBackground = Color(0xFF020D1A);
  static const Color darkCard = Color(0xFF122031); // Gray-Dark
  static const Color darkInput = Color(0xFF1F2A37); // Dark-2
  static const Color darkBorder = Color(0xFF27303E); // Stroke-Dark
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
  static const Color darkTextMuted = Color(0xFF6B7280);

  // Status & Priority Tokens
  // Completed / Success
  static const Color success = Color(0xFF22AD5C);
  static const Color successLight = Color(0xFFE9FBF0);

  // Pending / Low Priority / Warning
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFFFBEB);

  // In Progress / Info
  static const Color info = Color(0xFF3C50E0);
  static const Color infoLight = Color(0xFFE1E8FF);

  // High Priority / Danger / Error
  static const Color error = Color(0xFFF23030);
  static const Color errorLight = Color(0xFFFEF3F3);

  // Medium Priority
  static const Color mediumPriority = Color(0xFFF59460);
  static const Color mediumPriorityLight = Color(0xFFFFF7ED);
}
```

---

## 2. Typography

The design system uses **Satoshi** font family (Light 300, Regular 400, Medium 500, Bold 700, Black 900).

```dart
abstract final class AppTypography {
  static const String fontFamily = 'Satoshi';

  // Headlines
  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.4,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );

  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.27,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.33,
  );

  // Body text
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.57,
  );

  // Captions & Labels
  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.38,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.66,
  );
}
```

---

## 3. Spacing & Corner Radiuses

```dart
abstract final class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;

  // Corner Radiuses
  static const double radiusSm = 6.0;
  static const double radiusMd = 8.0; // rounded-lg
  static const double radiusLg = 12.0; // rounded-xl
  static const double radiusXl = 16.0; // rounded-2xl
  static const double radiusFull = 9999.0; // pill badges / avatars

  static const BorderRadius borderRadiusMd = BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius borderRadiusLg = BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius borderRadiusXl = BorderRadius.all(Radius.circular(radiusXl));
  static const BorderRadius borderRadiusFull = BorderRadius.all(Radius.circular(radiusFull));

  // Box Shadows
  static const BoxShadow shadowSm = BoxShadow(
    color: Color(0x0D000000),
    blurRadius: 4,
    offset: Offset(0, 1),
  );

  static const BoxShadow shadowMd = BoxShadow(
    color: Color(0x14000000),
    blurRadius: 8,
    offset: Offset(0, 4),
  );
}
```
