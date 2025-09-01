import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';


enum ButtonVariant {
  primary,
  secondary,
  outlined,
  text,
  danger,
}

enum ButtonSize {
  small,
  medium,
  large,
}

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final bool isLoading;
  final bool isDisabled;
  final Widget? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEffectivelyDisabled = isDisabled || isLoading || onPressed == null;

    return SizedBox(
      width: width,
      child: _buildButton(context, theme, isEffectivelyDisabled),
    );
  }

  Widget _buildButton(BuildContext context, ThemeData theme, bool isEffectivelyDisabled) {
    switch (variant) {
      case ButtonVariant.primary:
        return ElevatedButton(
          onPressed: isEffectivelyDisabled ? null : onPressed,
          style: _getElevatedButtonStyle(theme, isEffectivelyDisabled),
          child: _buildButtonContent(theme),
        );
      case ButtonVariant.secondary:
        return ElevatedButton(
          onPressed: isEffectivelyDisabled ? null : onPressed,
          style: _getSecondaryButtonStyle(theme, isEffectivelyDisabled),
          child: _buildButtonContent(theme),
        );
      case ButtonVariant.outlined:
        return OutlinedButton(
          onPressed: isEffectivelyDisabled ? null : onPressed,
          style: _getOutlinedButtonStyle(theme, isEffectivelyDisabled),
          child: _buildButtonContent(theme),
        );
      case ButtonVariant.text:
        return TextButton(
          onPressed: isEffectivelyDisabled ? null : onPressed,
          style: _getTextButtonStyle(theme, isEffectivelyDisabled),
          child: _buildButtonContent(theme),
        );
      case ButtonVariant.danger:
        return ElevatedButton(
          onPressed: isEffectivelyDisabled ? null : onPressed,
          style: _getDangerButtonStyle(theme, isEffectivelyDisabled),
          child: _buildButtonContent(theme),
        );
    }
  }

  Widget _buildButtonContent(ThemeData theme) {
    if (isLoading) {
      return SizedBox(
        height: _getIconSize(),
        width: _getIconSize(),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            _getLoadingColor(theme),
          ),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon!,
          const SizedBox(width: 8),
          Text(text),
        ],
      );
    }

    return Text(text);
  }

  ButtonStyle _getElevatedButtonStyle(ThemeData theme, bool isDisabled) {
    return ElevatedButton.styleFrom(
      backgroundColor: isDisabled
          ? AppColors.textTertiary.withValues(alpha: 0.3)
          : backgroundColor ?? AppColors.primaryGreen,
      foregroundColor: textColor ?? Colors.white,
      padding: padding ?? _getPadding(),
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(12),
      ),
      elevation: isDisabled ? 0 : 2,
      shadowColor: AppColors.shadow,
      textStyle: _getTextStyle(theme),
      minimumSize: Size(0, _getHeight()),
    );
  }

  ButtonStyle _getSecondaryButtonStyle(ThemeData theme, bool isDisabled) {
    return ElevatedButton.styleFrom(
      backgroundColor: isDisabled
          ? AppColors.textTertiary.withValues(alpha: 0.1)
          : backgroundColor ?? AppColors.surface,
      foregroundColor: isDisabled
          ? AppColors.textTertiary
          : textColor ?? AppColors.primaryGreen,
      padding: padding ?? _getPadding(),
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        side: BorderSide(
          color: isDisabled
              ? AppColors.textTertiary.withValues(alpha: 0.3)
              : AppColors.border,
        ),
      ),
      elevation: 0,
      textStyle: _getTextStyle(theme),
      minimumSize: Size(0, _getHeight()),
    );
  }

  ButtonStyle _getOutlinedButtonStyle(ThemeData theme, bool isDisabled) {
    return OutlinedButton.styleFrom(
      backgroundColor: backgroundColor ?? Colors.transparent,
      foregroundColor: isDisabled
          ? AppColors.textTertiary
          : textColor ?? AppColors.primaryGreen,
      padding: padding ?? _getPadding(),
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(12),
      ),
      side: BorderSide(
        color: isDisabled
            ? AppColors.textTertiary.withValues(alpha: 0.3)
            : AppColors.primaryGreen,
        width: 1.5,
      ),
      textStyle: _getTextStyle(theme),
      minimumSize: Size(0, _getHeight()),
    );
  }

  ButtonStyle _getTextButtonStyle(ThemeData theme, bool isDisabled) {
    return TextButton.styleFrom(
      foregroundColor: isDisabled
          ? AppColors.textTertiary
          : textColor ?? AppColors.primaryGreen,
      padding: padding ?? _getPadding(),
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
      textStyle: _getTextStyle(theme),
      minimumSize: Size(0, _getHeight()),
    );
  }

  ButtonStyle _getDangerButtonStyle(ThemeData theme, bool isDisabled) {
    return ElevatedButton.styleFrom(
      backgroundColor: isDisabled
          ? AppColors.textTertiary.withValues(alpha: 0.3)
          : backgroundColor ?? AppColors.error,
      foregroundColor: textColor ?? Colors.white,
      padding: padding ?? _getPadding(),
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(12),
      ),
      elevation: isDisabled ? 0 : 2,
      shadowColor: AppColors.shadow,
      textStyle: _getTextStyle(theme),
      minimumSize: Size(0, _getHeight()),
    );
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case ButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
      case ButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    }
  }

  double _getHeight() {
    switch (size) {
      case ButtonSize.small:
        return 36;
      case ButtonSize.medium:
        return 48;
      case ButtonSize.large:
        return 56;
    }
  }

  double _getIconSize() {
    switch (size) {
      case ButtonSize.small:
        return 16;
      case ButtonSize.medium:
        return 18;
      case ButtonSize.large:
        return 20;
    }
  }

  TextStyle _getTextStyle(ThemeData theme) {
    switch (size) {
      case ButtonSize.small:
        return theme.textTheme.labelMedium!.copyWith(
          fontWeight: FontWeight.w600,
        );
      case ButtonSize.medium:
        return theme.textTheme.labelLarge!.copyWith(
          fontWeight: FontWeight.w600,
        );
      case ButtonSize.large:
        return theme.textTheme.titleSmall!.copyWith(
          fontWeight: FontWeight.w600,
        );
    }
  }

  Color _getLoadingColor(ThemeData theme) {
    switch (variant) {
      case ButtonVariant.primary:
      case ButtonVariant.danger:
        return Colors.white;
      case ButtonVariant.secondary:
      case ButtonVariant.outlined:
      case ButtonVariant.text:
        return AppColors.primaryGreen;
    }
  }
}