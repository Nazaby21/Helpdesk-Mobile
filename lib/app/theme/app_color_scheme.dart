import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Semantic color tokens exposed via ThemeExtension so UI can access
/// theme-aware semantic colors via `Theme.of(context).extension<AppThemeColors>()`.
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  const AppThemeColors({
    required this.success,
    required this.successBg,
    required this.warning,
    required this.warningBg,
    required this.error,
    required this.errorBg,
    required this.info,
    required this.infoBg,
    required this.orangeAccent,
    required this.orangeBg,
    required this.border,
    required this.inputBorder,
    required this.textMuted,
    required this.chartCyan,
  });

  final Color success;
  final Color successBg;
  final Color warning;
  final Color warningBg;
  final Color error;
  final Color errorBg;
  final Color info;
  final Color infoBg;
  final Color orangeAccent;
  final Color orangeBg;
  final Color border;
  final Color inputBorder;
  final Color textMuted;
  final Color chartCyan;

  static const light = AppThemeColors(
    success: AppColors.success,
    successBg: AppColors.successBg,
    warning: AppColors.warning,
    warningBg: AppColors.warningBg,
    error: AppColors.error,
    errorBg: AppColors.errorBg,
    info: AppColors.info,
    infoBg: AppColors.infoBg,
    orangeAccent: AppColors.orangeAccent,
    orangeBg: AppColors.orangeBg,
    border: AppColors.lightBorder,
    inputBorder: AppColors.lightBorderInput,
    textMuted: AppColors.lightTextMuted,
    chartCyan: AppColors.chartCyan,
  );

  static const dark = AppThemeColors(
    success: AppColors.success,
    successBg: Color(0xFF0F3A22),
    warning: AppColors.warning,
    warningBg: Color(0xFF382806),
    error: AppColors.error,
    errorBg: Color(0xFF380C0C),
    info: AppColors.info,
    infoBg: Color(0xFF131D4A),
    orangeAccent: AppColors.orangeAccent,
    orangeBg: Color(0xFF3B1E0E),
    border: AppColors.darkBorder,
    inputBorder: AppColors.darkBorderInput,
    textMuted: AppColors.darkTextMuted,
    chartCyan: AppColors.chartCyan,
  );

  @override
  AppThemeColors copyWith({
    Color? success,
    Color? successBg,
    Color? warning,
    Color? warningBg,
    Color? error,
    Color? errorBg,
    Color? info,
    Color? infoBg,
    Color? orangeAccent,
    Color? orangeBg,
    Color? border,
    Color? inputBorder,
    Color? textMuted,
    Color? chartCyan,
  }) {
    return AppThemeColors(
      success: success ?? this.success,
      successBg: successBg ?? this.successBg,
      warning: warning ?? this.warning,
      warningBg: warningBg ?? this.warningBg,
      error: error ?? this.error,
      errorBg: errorBg ?? this.errorBg,
      info: info ?? this.info,
      infoBg: infoBg ?? this.infoBg,
      orangeAccent: orangeAccent ?? this.orangeAccent,
      orangeBg: orangeBg ?? this.orangeBg,
      border: border ?? this.border,
      inputBorder: inputBorder ?? this.inputBorder,
      textMuted: textMuted ?? this.textMuted,
      chartCyan: chartCyan ?? this.chartCyan,
    );
  }

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) return this;
    return AppThemeColors(
      success: Color.lerp(success, other.success, t) ?? success,
      successBg: Color.lerp(successBg, other.successBg, t) ?? successBg,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      warningBg: Color.lerp(warningBg, other.warningBg, t) ?? warningBg,
      error: Color.lerp(error, other.error, t) ?? error,
      errorBg: Color.lerp(errorBg, other.errorBg, t) ?? errorBg,
      info: Color.lerp(info, other.info, t) ?? info,
      infoBg: Color.lerp(infoBg, other.infoBg, t) ?? infoBg,
      orangeAccent: Color.lerp(orangeAccent, other.orangeAccent, t) ?? orangeAccent,
      orangeBg: Color.lerp(orangeBg, other.orangeBg, t) ?? orangeBg,
      border: Color.lerp(border, other.border, t) ?? border,
      inputBorder: Color.lerp(inputBorder, other.inputBorder, t) ?? inputBorder,
      textMuted: Color.lerp(textMuted, other.textMuted, t) ?? textMuted,
      chartCyan: Color.lerp(chartCyan, other.chartCyan, t) ?? chartCyan,
    );
  }
}
