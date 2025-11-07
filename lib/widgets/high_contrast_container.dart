import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../accessibility_provider.dart';
import '../theme_provider.dart';
import '../utils/accessibility_utils.dart';

/// A container widget that automatically applies high contrast styling
/// when high contrast mode is enabled. This ensures consistent behavior
/// across the app.
class HighContrastContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? borderWidth;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const HighContrastContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.boxShadow,
    this.gradient,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final highContrastMode = accessibilityProvider.highContrastMode;

    // Determine effective styling based on high contrast mode
    Color effectiveBackgroundColor;
    Color effectiveBorderColor;
    double effectiveBorderWidth;
    List<BoxShadow>? effectiveBoxShadow;
    Gradient? effectiveGradient;

    if (highContrastMode) {
      // High contrast mode: Use strong, clear colors
      effectiveBackgroundColor =
          backgroundColor ??
          AccessibilityUtils.getAccessibleSurfaceColor(context);
      effectiveBorderColor =
          borderColor ?? AccessibilityUtils.getAccessibleBorderColor(context);
      effectiveBorderWidth = borderWidth ?? 2.0;
      effectiveBoxShadow = null; // No shadows in high contrast mode
      effectiveGradient = null; // No gradients in high contrast mode
    } else {
      // Normal mode: Use provided styling or defaults
      effectiveBackgroundColor =
          backgroundColor ??
          (isDarkMode ? const Color(0xFF1E293B) : Colors.white);
      effectiveBorderColor = borderColor ?? Colors.transparent;
      effectiveBorderWidth = borderWidth ?? 0.0;
      effectiveBoxShadow = boxShadow;
      effectiveGradient = gradient;
    }

    final decoration = BoxDecoration(
      color: effectiveGradient == null ? effectiveBackgroundColor : null,
      gradient: effectiveGradient,
      borderRadius: borderRadius ?? BorderRadius.circular(8),
      border:
          effectiveBorderWidth > 0
              ? Border.all(
                color: effectiveBorderColor,
                width: effectiveBorderWidth,
              )
              : null,
      boxShadow: effectiveBoxShadow,
    );

    Widget containerWidget = Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: decoration,
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: containerWidget);
    }

    return containerWidget;
  }
}

/// A card widget that automatically applies high contrast styling
class HighContrastCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double? elevation;

  const HighContrastCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    return HighContrastContainer(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16),
      onTap: onTap,
      child: child,
    );
  }
}

/// A button that follows high contrast guidelines
class HighContrastButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final EdgeInsetsGeometry? padding;
  final double? fontSize;

  const HighContrastButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isPrimary = true,
    this.padding,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final fontSizeScale = MediaQuery.textScalerOf(context).scale(1.0);
    final effectiveFontSize = (fontSize ?? 16.0) * fontSizeScale;

    if (isPrimary) {
      return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding:
              padding ??
              EdgeInsets.symmetric(
                horizontal: 24 * fontSizeScale,
                vertical: 12 * fontSizeScale,
              ),
          textStyle: TextStyle(
            fontSize: effectiveFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        child: Text(text),
      );
    } else {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding:
              padding ??
              EdgeInsets.symmetric(
                horizontal: 24 * fontSizeScale,
                vertical: 12 * fontSizeScale,
              ),
          textStyle: TextStyle(
            fontSize: effectiveFontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: Text(text),
      );
    }
  }
}

/// Text that automatically applies high contrast colors
class HighContrastText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool isPrimary;

  const HighContrastText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final accessibleStyle = AccessibilityUtils.getTextStyle(
      context,
      baseStyle: style,
    );

    final Color textColor = AccessibilityUtils.getAccessibleColor(
      context,
      style?.color ??
          (Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black),
      isPrimary: isPrimary,
    );

    return Text(
      text,
      style: accessibleStyle.copyWith(color: textColor),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
