import 'package:flutter/material.dart';
import '../../app/constants/app_colors.dart';
import '../../app/constants/app_spacing.dart';

enum AppButtonVariant {
  primary,
  secondary,
  outline,
  danger,
  ghost,
}

enum AppButtonSize {
  sm(height: 32, fontSize: 12, horizontalPadding: 12, iconSize: 14),
  md(height: 40, fontSize: 14, horizontalPadding: 16, iconSize: 16),
  lg(height: 48, fontSize: 16, horizontalPadding: 24, iconSize: 18);

  const AppButtonSize({
    required this.height,
    required this.fontSize,
    required this.horizontalPadding,
    required this.iconSize,
  });

  final double height;
  final double fontSize;
  final double horizontalPadding;
  final double iconSize;
}

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.isLoading = false,
    this.disabled = false,
    this.isFullWidth = false,
    this.leftIcon,
    this.rightIcon,
  });

  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isLoading;
  final bool disabled;
  final bool isFullWidth;
  final Widget? leftIcon;
  final Widget? rightIcon;

  bool get _isInteractive => !disabled && !isLoading && onPressed != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final (backgroundColor, foregroundColor, border) = _resolveColors(isDark);

    Widget content = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: size.iconSize,
            height: size.iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ] else if (leftIcon != null) ...[
          IconTheme(
            data: IconThemeData(size: size.iconSize, color: foregroundColor),
            child: leftIcon!,
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        Text(
          text,
          style: TextStyle(
            fontSize: size.fontSize,
            fontWeight: FontWeight.w600,
            color: foregroundColor,
          ),
        ),
        if (!isLoading && rightIcon != null) ...[
          const SizedBox(width: AppSpacing.sm),
          IconTheme(
            data: IconThemeData(size: size.iconSize, color: foregroundColor),
            child: rightIcon!,
          ),
        ],
      ],
    );

    return Opacity(
      opacity: _isInteractive ? 1.0 : 0.6,
      child: Material(
        color: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusLg,
          side: border ?? BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _isInteractive ? onPressed : null,
          child: Container(
            height: size.height,
            padding: EdgeInsets.symmetric(horizontal: size.horizontalPadding),
            alignment: Alignment.center,
            child: content,
          ),
        ),
      ),
    );
  }

  (Color bg, Color fg, BorderSide? border) _resolveColors(bool isDark) {
    return switch (variant) {
      AppButtonVariant.primary => (
          AppColors.primary,
          Colors.white,
          null,
        ),
      AppButtonVariant.secondary => (
          isDark ? AppColors.darkInput : AppColors.buttonSecondaryBg,
          isDark ? AppColors.darkTextPrimary : AppColors.buttonSecondaryText,
          null,
        ),
      AppButtonVariant.outline => (
          Colors.transparent,
          isDark ? Colors.white : AppColors.buttonOutlineText,
          BorderSide(
            color: isDark ? AppColors.darkBorderInput : AppColors.buttonOutlineBorder,
            width: 1,
          ),
        ),
      AppButtonVariant.danger => (
          AppColors.buttonDangerBg,
          Colors.white,
          null,
        ),
      AppButtonVariant.ghost => (
          Colors.transparent,
          AppColors.primary,
          null,
        ),
    };
  }
}
