import 'package:flutter/material.dart';
import '../../app/constants/app_colors.dart';
import '../../app/constants/app_spacing.dart';
import '../../app/constants/app_typography.dart';
import '../../app/theme/app_color_scheme.dart';

enum AppBadgeVariant {
  success,
  warning,
  error,
  info,
  orange,
  neutral,
  defaultBadge,
}

typedef BadgeVariant = AppBadgeVariant;

class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    this.variant = AppBadgeVariant.neutral,
    this.icon,
  });

  final String label;
  final AppBadgeVariant variant;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeColors = theme.extension<AppThemeColors>();

    final (bg, text) = _resolveColors(isDark, themeColors);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppSpacing.borderRadiusFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            IconTheme(
              data: IconThemeData(size: 12, color: text),
              child: icon!,
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: text,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color) _resolveColors(bool isDark, AppThemeColors? themeColors) {
    switch (variant) {
      case AppBadgeVariant.success:
        return isDark
            ? (AppColors.success.withAlpha(50), AppColors.success)
            : (AppColors.successBg, AppColors.success);
      case AppBadgeVariant.warning:
        return isDark
            ? (AppColors.warning.withAlpha(50), AppColors.warning)
            : (AppColors.warningBg, AppColors.warning);
      case AppBadgeVariant.error:
        return isDark
            ? (AppColors.error.withAlpha(50), AppColors.error)
            : (AppColors.errorBg, AppColors.error);
      case AppBadgeVariant.info:
        return isDark
            ? (AppColors.info.withAlpha(50), AppColors.info)
            : (AppColors.infoBg, AppColors.info);
      case AppBadgeVariant.orange:
        return isDark
            ? (AppColors.orangeAccent.withAlpha(50), AppColors.orangeAccent)
            : (AppColors.orangeBg, AppColors.orangeAccent);
      case AppBadgeVariant.neutral:
      case AppBadgeVariant.defaultBadge:
        return isDark
            ? (AppColors.darkInput, AppColors.darkTextSecondary)
            : (AppColors.defaultBadgeBg, AppColors.defaultBadgeText);
    }
  }
}
