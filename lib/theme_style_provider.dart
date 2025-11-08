import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme_provider.dart';
import 'accessibility_provider.dart';

class ThemeStyleProvider {
  final ThemeProvider themeProvider;
  final AccessibilityProvider accessibilityProvider;

  ThemeStyleProvider({
    required this.themeProvider,
    required this.accessibilityProvider,
  });

  // Get the font family based on accessibility settings
  TextStyle getTextStyle(
    BuildContext context, {
    TextStyle? baseStyle,
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    TextDecoration? decoration,
    double? letterSpacing,
    double? height,
  }) {
    final isDarkMode = themeProvider.isDarkMode;
    final highContrastMode = accessibilityProvider.highContrastMode;

    // Get font family
    final fontFamily = accessibilityProvider.getActualFontFamily();

    // Get font size scale factor
    final fontSizeScale = MediaQuery.textScalerOf(context).scale(1.0);

    // Default text style using Google Fonts
    TextStyle defaultStyle = _getGoogleFontTextStyle(
      fontFamily: fontFamily,
      fontSize: 14.0 * fontSizeScale,
      fontWeight: FontWeight.normal,
      color: isDarkMode ? Colors.white : Colors.black87,
    );

    // Apply base style if provided
    if (baseStyle != null) {
      defaultStyle = _getGoogleFontTextStyle(
        fontFamily: fontFamily,
        fontSize:
            baseStyle.fontSize != null
                ? baseStyle.fontSize! * fontSizeScale
                : 14.0 * fontSizeScale,
        fontWeight: baseStyle.fontWeight,
        color: baseStyle.color,
        decoration: baseStyle.decoration,
        letterSpacing: baseStyle.letterSpacing,
        height: baseStyle.height,
      );
    }

    // Apply high contrast if enabled
    if (highContrastMode) {
      final highContrastColor = isDarkMode ? Colors.white : Colors.black;
      defaultStyle = defaultStyle.copyWith(
        color:
            color != null
                ? _increaseContrast(color, isDarkMode)
                : highContrastColor,
      );
    }

    // Apply other style overrides
    return defaultStyle.copyWith(
      fontSize: fontSize != null ? fontSize * fontSizeScale : null,
      fontWeight: fontWeight,
      color: highContrastMode ? null : color,
      decoration: decoration,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  // Helper method to get Google Font text style
  TextStyle _getGoogleFontTextStyle({
    required String fontFamily,
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    TextDecoration? decoration,
    double? letterSpacing,
    double? height,
  }) {
    // Ensure fontSize is never null to avoid assertion errors
    final safeFontSize = fontSize ?? 14.0;

    try {
      switch (fontFamily.toLowerCase()) {
        case 'roboto':
          return GoogleFonts.roboto(
            fontSize: safeFontSize,
            fontWeight: fontWeight,
            color: color,
            decoration: decoration,
            letterSpacing: letterSpacing,
            height: height,
          );
        case 'open':
        case 'opensans':
          return GoogleFonts.openSans(
            fontSize: safeFontSize,
            fontWeight: fontWeight,
            color: color,
            decoration: decoration,
            letterSpacing: letterSpacing,
            height: height,
          );
        case 'montserrat':
          return GoogleFonts.montserrat(
            fontSize: safeFontSize,
            fontWeight: fontWeight,
            color: color,
            decoration: decoration,
            letterSpacing: letterSpacing,
            height: height,
          );
        case 'lato':
          return GoogleFonts.lato(
            fontSize: safeFontSize,
            fontWeight: fontWeight,
            color: color,
            decoration: decoration,
            letterSpacing: letterSpacing,
            height: height,
          );
        case 'inter':
        default:
          return GoogleFonts.inter(
            fontSize: safeFontSize,
            fontWeight: fontWeight,
            color: color,
            decoration: decoration,
            letterSpacing: letterSpacing,
            height: height,
          );
      }
    } catch (e) {
      debugPrint('Error loading Google Font $fontFamily: $e');
      // Fallback to system font with safe fontSize
      return TextStyle(
        fontSize: safeFontSize,
        fontWeight: fontWeight,
        color: color,
        decoration: decoration,
        letterSpacing: letterSpacing,
        height: height,
      );
    }
  }

  // Helper method to increase contrast
  Color _increaseContrast(Color color, bool isDarkMode) {
    if (isDarkMode) {
      // In dark mode, make colors brighter
      final hsl = HSLColor.fromColor(color);
      return hsl.withLightness((hsl.lightness + 0.2).clamp(0.0, 1.0)).toColor();
    } else {
      // In light mode, make colors darker
      final hsl = HSLColor.fromColor(color);
      return hsl.withLightness((hsl.lightness - 0.2).clamp(0.0, 1.0)).toColor();
    }
  }

  // Apply font family to theme
  ThemeData getThemeWithAccessibility(BuildContext context) {
    final baseTheme = themeProvider.getTheme(context);
    final fontFamily = accessibilityProvider.getActualFontFamily();
    final fontSizeScale = MediaQuery.textScalerOf(context).scale(1.0);
    final highContrastMode = accessibilityProvider.highContrastMode;
    final isDarkMode = themeProvider.isDarkMode;

    // Get text theme with adjusted font family and size using Google Fonts
    TextTheme adjustedTextTheme = _getGoogleFontsTextTheme(
      fontFamily,
      fontSizeScale,
      highContrastMode,
      isDarkMode,
    );

    // Apply high contrast theme modifications if enabled
    if (highContrastMode) {
      return _getHighContrastTheme(
        baseTheme,
        adjustedTextTheme,
        fontFamily,
        fontSizeScale,
        isDarkMode,
      );
    }

    // Return modified theme without high contrast
    return baseTheme.copyWith(
      textTheme: adjustedTextTheme,
      primaryTextTheme: adjustedTextTheme,
      // Adjust button themes
      elevatedButtonTheme: _getAdjustedButtonTheme(
        baseTheme,
        fontFamily,
        fontSizeScale,
        highContrastMode,
      ),
      textButtonTheme: _getAdjustedTextButtonTheme(
        baseTheme,
        fontFamily,
        fontSizeScale,
        highContrastMode,
      ),
    );
  }

  // Create a comprehensive high contrast theme
  ThemeData _getHighContrastTheme(
    ThemeData baseTheme,
    TextTheme textTheme,
    String fontFamily,
    double fontSizeScale,
    bool isDarkMode,
  ) {
    // High contrast color scheme with better visual hierarchy
    final primaryColor = isDarkMode ? Colors.white : Colors.black;
    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final surfaceColor =
        isDarkMode
            ? const Color(0xFF1A1A1A)
            : const Color(0xFFF8F8F8); // Softer surface color
    final onSurfaceColor = isDarkMode ? Colors.white : Colors.black;
    final dividerColor = isDarkMode ? Colors.white : Colors.black;

    return baseTheme.copyWith(
      // Core colors
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,

      // Color scheme
      colorScheme: ColorScheme(
        brightness: isDarkMode ? Brightness.dark : Brightness.light,
        primary: primaryColor,
        onPrimary: isDarkMode ? Colors.black : Colors.white,
        secondary: primaryColor,
        onSecondary: isDarkMode ? Colors.black : Colors.white,
        error: isDarkMode ? const Color(0xFFFF6B6B) : const Color(0xFFD32F2F),
        onError: isDarkMode ? Colors.black : Colors.white,
        surface: surfaceColor,
        onSurface: onSurfaceColor,
        outline: dividerColor,
        shadow: Colors.transparent, // No shadows in high contrast
      ),

      // Text themes
      textTheme: textTheme,
      primaryTextTheme: textTheme,

      // AppBar theme
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: onSurfaceColor,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: onSurfaceColor),
        actionsIconTheme: IconThemeData(color: onSurfaceColor),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: onSurfaceColor,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Card theme
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: dividerColor, width: 2),
        ),
      ),

      // Button themes
      elevatedButtonTheme: _getHighContrastElevatedButtonTheme(
        fontFamily,
        fontSizeScale,
        isDarkMode,
      ),
      textButtonTheme: _getHighContrastTextButtonTheme(
        fontFamily,
        fontSizeScale,
        isDarkMode,
      ),
      outlinedButtonTheme: _getHighContrastOutlinedButtonTheme(
        fontFamily,
        fontSizeScale,
        isDarkMode,
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: dividerColor, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: dividerColor, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor, width: 3),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color:
                isDarkMode ? const Color(0xFFFF6B6B) : const Color(0xFFD32F2F),
            width: 2,
          ),
        ),
        labelStyle: textTheme.bodyLarge?.copyWith(color: onSurfaceColor),
        hintStyle: textTheme.bodyLarge?.copyWith(
          color: onSurfaceColor.withAlpha(178),
        ),
      ),

      // Divider theme
      dividerTheme: DividerThemeData(color: dividerColor, thickness: 2),

      // Icon theme
      iconTheme: IconThemeData(color: onSurfaceColor, size: 24 * fontSizeScale),
      primaryIconTheme: IconThemeData(
        color: onSurfaceColor,
        size: 24 * fontSizeScale,
      ),

      // Switch theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return isDarkMode ? Colors.black : Colors.white;
          }
          return isDarkMode ? Colors.white : Colors.black;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return dividerColor;
        }),
        overlayColor: WidgetStateProperty.all(Colors.transparent),
      ),

      // Checkbox theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(
          isDarkMode ? Colors.black : Colors.white,
        ),
        side: BorderSide(color: dividerColor, width: 2),
      ),

      // Dialog theme
      dialogTheme: DialogThemeData(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: dividerColor, width: 2),
        ),
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          color: onSurfaceColor,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: textTheme.bodyLarge?.copyWith(color: onSurfaceColor),
      ),

      // Bottom sheet theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          side: BorderSide(color: dividerColor, width: 2),
        ),
      ),
    );
  }

  // Helper to create Google Fonts text theme
  TextTheme _getGoogleFontsTextTheme(
    String fontFamily,
    double fontSizeScale,
    bool highContrastMode,
    bool isDarkMode,
  ) {
    final textColor =
        highContrastMode
            ? (isDarkMode ? Colors.white : Colors.black)
            : (isDarkMode ? Colors.white : Colors.black87);

    try {
      // Get a base text theme to ensure all text styles have proper fontSize values
      final baseTheme = ThemeData.light().textTheme;

      TextTheme googleFontTheme;
      switch (fontFamily.toLowerCase()) {
        case 'roboto':
          googleFontTheme = GoogleFonts.robotoTextTheme(baseTheme);
          break;
        case 'open':
        case 'opensans':
          googleFontTheme = GoogleFonts.openSansTextTheme(baseTheme);
          break;
        case 'montserrat':
          googleFontTheme = GoogleFonts.montserratTextTheme(baseTheme);
          break;
        case 'lato':
          googleFontTheme = GoogleFonts.latoTextTheme(baseTheme);
          break;
        case 'inter':
        default:
          googleFontTheme = GoogleFonts.interTextTheme(baseTheme);
          break;
      }

      // Apply scaling and colors safely
      if (fontSizeScale == 1.0) {
        // If no scaling needed, just apply colors
        return googleFontTheme.apply(
          bodyColor: textColor,
          displayColor: textColor,
        );
      } else {
        // If scaling needed, manually scale each text style to avoid assertion errors
        return _applyFontSizeScalingManually(
          googleFontTheme,
          fontSizeScale,
          textColor,
        );
      }
    } catch (e) {
      debugPrint('Error creating Google Fonts text theme for $fontFamily: $e');
      // Fallback to default text theme with manual scaling
      final baseTheme = ThemeData.light().textTheme;
      if (fontSizeScale == 1.0) {
        return baseTheme.apply(bodyColor: textColor, displayColor: textColor);
      } else {
        return _applyFontSizeScalingManually(
          baseTheme,
          fontSizeScale,
          textColor,
        );
      }
    }
  }

  // Helper method to manually apply font size scaling to avoid assertion errors
  TextTheme _applyFontSizeScalingManually(
    TextTheme theme,
    double fontSizeScale,
    Color textColor,
  ) {
    return TextTheme(
      displayLarge: _scaleTextStyle(
        theme.displayLarge,
        fontSizeScale,
        textColor,
      ),
      displayMedium: _scaleTextStyle(
        theme.displayMedium,
        fontSizeScale,
        textColor,
      ),
      displaySmall: _scaleTextStyle(
        theme.displaySmall,
        fontSizeScale,
        textColor,
      ),
      headlineLarge: _scaleTextStyle(
        theme.headlineLarge,
        fontSizeScale,
        textColor,
      ),
      headlineMedium: _scaleTextStyle(
        theme.headlineMedium,
        fontSizeScale,
        textColor,
      ),
      headlineSmall: _scaleTextStyle(
        theme.headlineSmall,
        fontSizeScale,
        textColor,
      ),
      titleLarge: _scaleTextStyle(theme.titleLarge, fontSizeScale, textColor),
      titleMedium: _scaleTextStyle(theme.titleMedium, fontSizeScale, textColor),
      titleSmall: _scaleTextStyle(theme.titleSmall, fontSizeScale, textColor),
      bodyLarge: _scaleTextStyle(theme.bodyLarge, fontSizeScale, textColor),
      bodyMedium: _scaleTextStyle(theme.bodyMedium, fontSizeScale, textColor),
      bodySmall: _scaleTextStyle(theme.bodySmall, fontSizeScale, textColor),
      labelLarge: _scaleTextStyle(theme.labelLarge, fontSizeScale, textColor),
      labelMedium: _scaleTextStyle(theme.labelMedium, fontSizeScale, textColor),
      labelSmall: _scaleTextStyle(theme.labelSmall, fontSizeScale, textColor),
    );
  }

  // Helper method to scale individual TextStyle
  TextStyle? _scaleTextStyle(TextStyle? style, double scale, Color textColor) {
    if (style == null) return null;

    return style.copyWith(
      fontSize: (style.fontSize ?? 14.0) * scale,
      color: textColor,
    );
  }

  // High contrast elevated button theme
  ElevatedButtonThemeData _getHighContrastElevatedButtonTheme(
    String fontFamily,
    double fontSizeScale,
    bool isDarkMode,
  ) {
    final primaryColor = isDarkMode ? Colors.white : Colors.black;
    final onPrimaryColor = isDarkMode ? Colors.black : Colors.white;

    return ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return isDarkMode ? Colors.grey[800] : Colors.grey[300];
          }
          return primaryColor;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return isDarkMode ? Colors.grey[500] : Colors.grey[600];
          }
          return onPrimaryColor;
        }),
        elevation: WidgetStateProperty.all(0),
        shadowColor: WidgetStateProperty.all(Colors.transparent),
        surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
        side: WidgetStateProperty.all(
          BorderSide(color: primaryColor, width: 2),
        ),
        textStyle: WidgetStateProperty.all(
          _getGoogleFontTextStyle(
            fontFamily: fontFamily,
            fontSize: 16 * fontSizeScale,
            fontWeight: FontWeight.bold,
          ),
        ),
        padding: WidgetStateProperty.all(
          EdgeInsets.symmetric(
            horizontal: 24 * fontSizeScale,
            vertical: 12 * fontSizeScale,
          ),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  // High contrast text button theme
  TextButtonThemeData _getHighContrastTextButtonTheme(
    String fontFamily,
    double fontSizeScale,
    bool isDarkMode,
  ) {
    final primaryColor = isDarkMode ? Colors.white : Colors.black;

    return TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return isDarkMode ? Colors.grey[500] : Colors.grey[600];
          }
          return primaryColor;
        }),
        overlayColor: WidgetStateProperty.all(primaryColor.withAlpha(25)),
        side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.focused)) {
            return BorderSide(color: primaryColor, width: 2);
          }
          return BorderSide.none;
        }),
        textStyle: WidgetStateProperty.all(
          _getGoogleFontTextStyle(
            fontFamily: fontFamily,
            fontSize: 16 * fontSizeScale,
            fontWeight: FontWeight.w600,
          ),
        ),
        padding: WidgetStateProperty.all(
          EdgeInsets.symmetric(
            horizontal: 16 * fontSizeScale,
            vertical: 8 * fontSizeScale,
          ),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  // High contrast outlined button theme
  OutlinedButtonThemeData _getHighContrastOutlinedButtonTheme(
    String fontFamily,
    double fontSizeScale,
    bool isDarkMode,
  ) {
    final primaryColor = isDarkMode ? Colors.white : Colors.black;

    return OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return isDarkMode ? Colors.grey[500] : Colors.grey[600];
          }
          return primaryColor;
        }),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return primaryColor.withAlpha(25);
          }
          return Colors.transparent;
        }),
        elevation: WidgetStateProperty.all(0),
        shadowColor: WidgetStateProperty.all(Colors.transparent),
        side: WidgetStateProperty.all(
          BorderSide(color: primaryColor, width: 2),
        ),
        textStyle: WidgetStateProperty.all(
          _getGoogleFontTextStyle(
            fontFamily: fontFamily,
            fontSize: 16 * fontSizeScale,
            fontWeight: FontWeight.w600,
          ),
        ),
        padding: WidgetStateProperty.all(
          EdgeInsets.symmetric(
            horizontal: 24 * fontSizeScale,
            vertical: 12 * fontSizeScale,
          ),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  // Helper to adjust button theme
  ElevatedButtonThemeData _getAdjustedButtonTheme(
    ThemeData baseTheme,
    String fontFamily,
    double fontSizeScale,
    bool highContrastMode,
  ) {
    return ElevatedButtonThemeData(
      style: ButtonStyle(
        textStyle: WidgetStateProperty.all(
          _getGoogleFontTextStyle(
            fontFamily: fontFamily,
            fontSize: 14 * fontSizeScale,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Helper to adjust text button theme
  TextButtonThemeData _getAdjustedTextButtonTheme(
    ThemeData baseTheme,
    String fontFamily,
    double fontSizeScale,
    bool highContrastMode,
  ) {
    return TextButtonThemeData(
      style: ButtonStyle(
        textStyle: WidgetStateProperty.all(
          _getGoogleFontTextStyle(
            fontFamily: fontFamily,
            fontSize: 14 * fontSizeScale,
            fontWeight: FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // Get animation duration based on reduce motion setting
  Duration getAnimationDuration(Duration normalDuration) {
    return accessibilityProvider.reduceMotion
        ? const Duration(milliseconds: 100)
        : normalDuration;
  }

  // Get animation curve based on reduce motion setting
  Curve getAnimationCurve() {
    return accessibilityProvider.reduceMotion
        ? Curves.linear
        : ThemeProvider.animationCurveDefault;
  }
}
