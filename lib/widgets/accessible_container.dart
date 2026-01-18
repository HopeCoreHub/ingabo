import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../accessibility_provider.dart';
import '../theme_provider.dart';
// Accessibility imports

class AccessibleContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final BoxBorder? border;
  final BorderRadiusGeometry? borderRadius;
  final List<BoxShadow>? boxShadow;
  final Gradient? gradient;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;
  final VoidCallback? onTap;

  const AccessibleContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.foregroundColor,
    this.border,
    this.borderRadius,
    this.boxShadow,
    this.gradient,
    this.width,
    this.height,
    this.alignment,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final highContrastMode = accessibilityProvider.highContrastMode;

    // Apply high contrast adjustments if needed
    Color effectiveBackgroundColor;
    Gradient? effectiveGradient;
    List<BoxShadow>? effectiveBoxShadow;

    if (highContrastMode) {
      // In high contrast mode, simplify the background
      effectiveBackgroundColor = isDarkMode ? Colors.black : Colors.white;
      effectiveGradient = null; // Remove gradients in high contrast mode

      // Increase border contrast if borders are used
      final effectiveBorder =
          border != null
              ? Border.all(
                color: isDarkMode ? Colors.white : Colors.black,
                width: 2.0,
              )
              : Border.all(
                color: isDarkMode ? Colors.white : Colors.black,
                width: 1.0,
              );

      // Modify or remove shadows for high contrast
      effectiveBoxShadow = null; // Remove shadows in high contrast mode

      // Create the GestureDetector or Container based on whether onTap is provided
      return onTap != null
          ? GestureDetector(
            onTap: onTap,
            child: Container(
              width: width,
              height: height,
              alignment: alignment,
              padding: padding,
              margin: margin,
              decoration: BoxDecoration(
                color: effectiveBackgroundColor,
                border: effectiveBorder,
                borderRadius: borderRadius as BorderRadius?,
                boxShadow: effectiveBoxShadow,
              ),
              child: child,
            ),
          )
          : Container(
            width: width,
            height: height,
            alignment: alignment,
            padding: padding,
            margin: margin,
            decoration: BoxDecoration(
              color: effectiveBackgroundColor,
              border: effectiveBorder,
              borderRadius: borderRadius as BorderRadius?,
              boxShadow: effectiveBoxShadow,
            ),
            child: child,
          );
    } else {
      // Standard mode - use provided values
      effectiveBackgroundColor =
          backgroundColor ??
          (isDarkMode ? const Color(0xFF1E293B) : Colors.white);
      effectiveGradient = gradient;
      effectiveBoxShadow = boxShadow;

      return onTap != null
          ? GestureDetector(
            onTap: onTap,
            child: Container(
              width: width,
              height: height,
              alignment: alignment,
              padding: padding,
              margin: margin,
              decoration: BoxDecoration(
                color: effectiveBackgroundColor,
                gradient: effectiveGradient,
                border: border,
                borderRadius: borderRadius as BorderRadius?,
                boxShadow: effectiveBoxShadow,
              ),
              child: child,
            ),
          )
          : Container(
            width: width,
            height: height,
            alignment: alignment,
            padding: padding,
            margin: margin,
            decoration: BoxDecoration(
              color: effectiveBackgroundColor,
              gradient: effectiveGradient,
              border: border,
              borderRadius: borderRadius as BorderRadius?,
              boxShadow: effectiveBoxShadow,
            ),
            child: child,
          );
    }
  }
}

// Accessible card widget that applies high contrast mode
class AccessibleCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final BorderRadiusGeometry? borderRadius;
  final VoidCallback? onTap;
  final double? elevation;

  const AccessibleCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.borderRadius,
    this.onTap,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final highContrastMode = accessibilityProvider.highContrastMode;

    // For high contrast mode, use a more basic card with clear borders
    if (highContrastMode) {
      return Card(
        margin: margin ?? const EdgeInsets.all(0),
        elevation: 0, // No elevation in high contrast mode
        color: isDarkMode ? Colors.black : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius:
              (borderRadius as BorderRadius?) ?? BorderRadius.circular(8),
          side: BorderSide(
            color: isDarkMode ? Colors.white : Colors.black,
            width: 2.0,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius:
              (borderRadius is BorderRadius)
                  ? borderRadius as BorderRadius
                  : BorderRadius.circular(8),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      );
    } else {
      // Standard mode card
      return Card(
        margin: margin,
        elevation: elevation ?? 1.0,
        color: color ?? (isDarkMode ? const Color(0xFF1E293B) : Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius:
              (borderRadius as BorderRadius?) ?? BorderRadius.circular(8),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius:
              (borderRadius is BorderRadius)
                  ? borderRadius as BorderRadius
                  : BorderRadius.circular(8),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      );
    }
  }
}
