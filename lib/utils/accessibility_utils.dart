import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../accessibility_provider.dart';
import '../services/speech_service.dart';
import '../theme_style_provider.dart';
import '../theme_provider.dart';

class AccessibilityUtils {
  // Get text style with accessibility settings applied
  static TextStyle getTextStyle(
    BuildContext context, {
    TextStyle? baseStyle,
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    TextDecoration? decoration,
    double? letterSpacing,
    double? height,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context, listen: false);
    
    final themeStyleProvider = ThemeStyleProvider(
      themeProvider: themeProvider,
      accessibilityProvider: accessibilityProvider,
    );
    
    return themeStyleProvider.getTextStyle(
      context,
      baseStyle: baseStyle,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      decoration: decoration,
      letterSpacing: letterSpacing,
      height: height,
    );
  }
  
  // Get a high-contrast compliant color based on accessibility settings
  static Color getAccessibleColor(BuildContext context, Color originalColor, {bool isBackground = false, bool isPrimary = false}) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    
    // If high contrast mode is not enabled, return the original color
    if (!accessibilityProvider.highContrastMode) {
      return originalColor;
    }
    
    // In high contrast mode, use standardized colors
    if (isPrimary) {
      // Primary colors (buttons, links, etc.)
      return isDarkMode ? Colors.white : Colors.black;
    }
    
    if (isBackground) {
      // Background colors - pure black/white for maximum contrast
      return isDarkMode ? Colors.black : Colors.white;
    } else {
      // Text and UI elements - ensure maximum contrast
      return isDarkMode ? Colors.white : Colors.black;
    }
  }
  
  // Get high contrast surface color
  static Color getAccessibleSurfaceColor(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    
    if (!accessibilityProvider.highContrastMode) {
      return isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    }
    
    // In high contrast mode, use slightly different shade for surfaces with better contrast
    return isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFF8F8F8);
  }
  
  // Get high contrast border color
  static Color getAccessibleBorderColor(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    
    if (!accessibilityProvider.highContrastMode) {
      return isDarkMode ? Colors.white24 : Colors.black12;
    }
    
    // In high contrast mode, use strong borders
    return isDarkMode ? Colors.white : Colors.black;
  }
  
  // Helper method to check if high contrast mode is enabled
  static bool isHighContrastEnabled(BuildContext context) {
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context, listen: false);
    return accessibilityProvider.highContrastMode;
  }
  
  // Get animation duration with reduce motion setting applied
  static Duration getAnimationDuration(BuildContext context, Duration normalDuration) {
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context, listen: false);
    return accessibilityProvider.reduceMotion 
      ? const Duration(milliseconds: 100) 
      : normalDuration;
  }
  
  // Get animation curve with reduce motion setting applied
  static Curve getAnimationCurve(BuildContext context) {
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context, listen: false);
    return accessibilityProvider.reduceMotion 
      ? Curves.linear
      : ThemeProvider.animationCurveDefault;
  }
  
  // Speak text if text-to-speech is enabled
  static Future<void> speakText(BuildContext context, String text) async {
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context, listen: false);
    if (accessibilityProvider.textToSpeech) {
      final speechService = Provider.of<SpeechService>(context, listen: false);
      await speechService.speak(text);
    }
  }
  
  // Start listening for speech if voice-to-text is enabled
  static Future<void> startListening(
    BuildContext context, {
    required Function(String) onResult,
    required Function() onListeningComplete,
  }) async {
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context, listen: false);
    if (accessibilityProvider.voiceToText) {
      final speechService = Provider.of<SpeechService>(context, listen: false);
      await speechService.startListening(
        onResult: onResult,
        onListeningComplete: onListeningComplete,
      );
    }
  }
  
  // Create a text-to-speech button
  static Widget createTextToSpeechButton(
    BuildContext context, {
    required String textToSpeak,
    Color? color,
    double? size,
  }) {
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final speechService = Provider.of<SpeechService>(context);
    
    // If text-to-speech is disabled, return an empty container
    if (!accessibilityProvider.textToSpeech) {
      return const SizedBox.shrink();
    }
    
    final isDarkMode = themeProvider.isDarkMode;
    final buttonColor = color ?? (isDarkMode ? Colors.white70 : Colors.black54);
    
    return IconButton(
      icon: Icon(
        speechService.isSpeaking ? Icons.stop : Icons.volume_up,
        color: buttonColor,
        size: size ?? 20,
      ),
      onPressed: () async {
        if (speechService.isSpeaking) {
          await speechService.stop();
        } else {
          await speechService.speak(textToSpeak);
        }
      },
    );
  }
  
  // Create a voice-to-text button
  static Widget createVoiceToTextButton(
    BuildContext context, {
    required Function(String) onResult,
    Color? color,
    double? size,
  }) {
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final speechService = Provider.of<SpeechService>(context);
    
    // If voice-to-text is disabled, return an empty container
    if (!accessibilityProvider.voiceToText) {
      return const SizedBox.shrink();
    }
    
    final isDarkMode = themeProvider.isDarkMode;
    final buttonColor = color ?? getAccessibleColor(context, 
        isDarkMode ? Colors.white70 : Colors.black54);
    
    return IconButton(
      icon: Icon(
        speechService.isListening ? Icons.mic : Icons.mic_none,
        color: buttonColor,
        size: size ?? 20,
      ),
      onPressed: () async {
        if (speechService.isListening) {
          await speechService.stopListening();
        } else {
          await speechService.startListening(
            onResult: onResult,
            onListeningComplete: () {},
          );
        }
      },
    );
  }
  
  // Get appropriate elevation for high contrast mode
  static double getAccessibleElevation(BuildContext context, double normalElevation) {
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context, listen: false);
    
    // No elevation in high contrast mode
    if (accessibilityProvider.highContrastMode) {
      return 0.0;
    }
    
    return normalElevation;
  }
  
  // Get appropriate shadow for high contrast mode
  static List<BoxShadow>? getAccessibleShadow(BuildContext context, List<BoxShadow>? normalShadow) {
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context, listen: false);
    
    // No shadows in high contrast mode
    if (accessibilityProvider.highContrastMode) {
      return null;
    }
    
    return normalShadow;
  }
  
  // Get appropriate border width for high contrast mode
  static double getAccessibleBorderWidth(BuildContext context, double normalWidth) {
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context, listen: false);
    
    // Thicker borders in high contrast mode
    if (accessibilityProvider.highContrastMode) {
      return normalWidth > 0 ? math.max(normalWidth, 2.0) : 2.0;
    }
    
    return normalWidth;
  }
} 