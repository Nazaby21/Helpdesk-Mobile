import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';
import 'app_color_scheme.dart';

abstract final class AppTheme {
  static ThemeData get lightTheme {
    final textTheme = _buildTextTheme(
      primaryColor: AppColors.lightTextPrimary,
      secondaryColor: AppColors.lightTextSecondary,
      mutedColor: AppColors.lightTextMuted,
    );

    final colorScheme = const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFEEF2FF),
      onPrimaryContainer: AppColors.primaryHover,
      secondary: AppColors.primaryHover,
      onSecondary: Colors.white,
      surface: AppColors.lightCard,
      onSurface: AppColors.lightTextPrimary,
      error: AppColors.error,
      onError: Colors.white,
      outline: AppColors.lightBorder,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: AppTypography.fontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.lightScaffold,
      textTheme: textTheme,
      dividerTheme: const DividerThemeData(
        color: AppColors.lightBorder,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightCard,
        foregroundColor: AppColors.lightTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 18,
          fontWeight: AppTypography.bold,
          color: AppColors.lightTextPrimary,
        ),
        iconTheme: IconThemeData(color: AppColors.lightTextPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusXl,
          side: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightInput,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.lightTextMuted),
        labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.lightTextSecondary),
        border: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusInput,
          borderSide: const BorderSide(color: AppColors.lightBorderInput, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusInput,
          borderSide: const BorderSide(color: AppColors.lightBorderInput, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusInput,
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusInput,
          borderSide: const BorderSide(color: AppColors.errorInput, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusInput,
          borderSide: const BorderSide(color: AppColors.errorInput, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusLg),
          textStyle: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.buttonOutlineText,
          side: const BorderSide(color: AppColors.buttonOutlineBorder, width: 1),
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusLg),
          textStyle: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      extensions: const [
        AppThemeColors.light,
      ],
    );
  }

  static ThemeData get darkTheme {
    final textTheme = _buildTextTheme(
      primaryColor: AppColors.darkTextPrimary,
      secondaryColor: AppColors.darkTextSecondary,
      mutedColor: AppColors.darkTextMuted,
    );

    final colorScheme = const ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFF1E1E4F),
      onPrimaryContainer: Colors.white,
      secondary: AppColors.primaryHover,
      onSecondary: Colors.white,
      surface: AppColors.darkCard,
      onSurface: AppColors.darkTextPrimary,
      error: AppColors.error,
      onError: Colors.white,
      outline: AppColors.darkBorder,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: AppTypography.fontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.darkScaffold,
      textTheme: textTheme,
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkCard,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 18,
          fontWeight: AppTypography.bold,
          color: AppColors.darkTextPrimary,
        ),
        iconTheme: IconThemeData(color: AppColors.darkTextPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusXl,
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkInput,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.darkTextMuted),
        labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.darkTextSecondary),
        border: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusInput,
          borderSide: const BorderSide(color: AppColors.darkBorderInput, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusInput,
          borderSide: const BorderSide(color: AppColors.darkBorderInput, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusInput,
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusInput,
          borderSide: const BorderSide(color: AppColors.errorInput, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusInput,
          borderSide: const BorderSide(color: AppColors.errorInput, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusLg),
          textStyle: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: AppColors.darkBorderInput, width: 1),
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusLg),
          textStyle: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      extensions: const [
        AppThemeColors.dark,
      ],
    );
  }

  static TextTheme _buildTextTheme({
    required Color primaryColor,
    required Color secondaryColor,
    required Color mutedColor,
  }) {
    return TextTheme(
      headlineMedium: AppTypography.headlineMedium.copyWith(color: primaryColor),
      headlineSmall: AppTypography.headlineSmall.copyWith(color: primaryColor),
      titleLarge: AppTypography.titleLarge.copyWith(color: primaryColor),
      titleMedium: AppTypography.titleLarge.copyWith(
        fontSize: 18,
        height: 24 / 18,
        color: primaryColor,
      ),
      bodyLarge: AppTypography.bodyLarge.copyWith(color: primaryColor),
      bodyMedium: AppTypography.bodyMedium.copyWith(color: secondaryColor),
      bodySmall: AppTypography.labelSmall.copyWith(color: mutedColor),
      labelLarge: AppTypography.bodyMedium.copyWith(
        fontWeight: AppTypography.medium,
        color: primaryColor,
      ),
      labelSmall: AppTypography.labelSmall.copyWith(color: mutedColor),
    );
  }
}
