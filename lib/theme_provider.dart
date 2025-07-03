import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool _useSystemTheme = true;
  static const String _darkModeKey = 'dark_mode';
  static const String _useSystemThemeKey = 'use_system_theme';

  // Animation configurations
  static const Duration animationDurationShort = Duration(milliseconds: 200);
  static const Duration animationDurationMedium = Duration(milliseconds: 350);
  static const Duration animationDurationLong = Duration(milliseconds: 500);
  
  static const Curve animationCurveDefault = Curves.easeOutCubic;
  static const Curve animationCurveFast = Curves.easeOut;
  static const Curve animationCurveSnappy = Curves.easeOutBack;
  static const Curve animationCurveSmooth = Curves.fastOutSlowIn;
  
  // Page transition settings
  static const Duration pageTransitionDuration = Duration(milliseconds: 300);
  static const Curve pageTransitionCurve = Curves.fastOutSlowIn;
  
  // Stagger intervals
  static const Duration staggerInterval = Duration(milliseconds: 50);

  ThemeProvider() {
    _loadPreferences();
  }

  // Getters
  bool get isDarkMode => _isDarkMode;
  bool get useSystemTheme => _useSystemTheme;

  // Load theme preferences
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final useSystemTheme = prefs.getBool(_useSystemThemeKey) ?? true;
    
    if (useSystemTheme) {
      // Get system theme
      final brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
      _isDarkMode = brightness == Brightness.dark;
      _useSystemTheme = true;
    } else {
      _isDarkMode = prefs.getBool(_darkModeKey) ?? false;
      _useSystemTheme = false;
    }
    
    notifyListeners();
  }

  // Toggle dark mode
  Future<void> toggleDarkMode(bool value) async {
    _isDarkMode = value;
    _useSystemTheme = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, _isDarkMode);
    await prefs.setBool(_useSystemThemeKey, _useSystemTheme);
    notifyListeners();
  }

  // Set use system theme
  Future<void> setUseSystemTheme(bool value) async {
    _useSystemTheme = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useSystemThemeKey, value);
    
    if (value) {
      // Get system theme
      final brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
      _isDarkMode = brightness == Brightness.dark;
      notifyListeners();
    }
  }

  // Get theme data
  ThemeData getTheme(BuildContext context) {
    return _isDarkMode ? _buildDarkTheme(context) : _buildLightTheme(context);
  }
  
  // Build dark theme
  ThemeData _buildDarkTheme(BuildContext context) {
    final base = ThemeData.dark();
    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFF111827),
      primaryColor: const Color(0xFF8A4FFF),
      cardColor: const Color(0xFF1E293B),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF8A4FFF),
        secondary: Color(0xFF6D28D9),
        background: Color(0xFF111827),
        surface: Color(0xFF1E293B),
        onBackground: Colors.white,
        error: Color(0xFFEF4444),
      ),
      dialogBackgroundColor: const Color(0xFF1E293B),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF111827),
        elevation: 0,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  // Build light theme
  ThemeData _buildLightTheme(BuildContext context) {
    final base = ThemeData.light();
    return base.copyWith(
      scaffoldBackgroundColor: Colors.white,
      primaryColor: const Color(0xFFE53935),
      cardColor: const Color(0xFFF1F5F9),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFFE53935),
        secondary: Color(0xFFD32F2F),
        background: Colors.white,
        surface: Color(0xFFF1F5F9),
        onBackground: Colors.black,
        error: Color(0xFFBA000D),
      ),
      dialogBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  // Page route builder with custom transitions
  static PageRouteBuilder<T> createAnimatedRoute<T>({
    required Widget page, 
    RouteSettings? settings,
    bool fadeIn = true,
    bool slideUp = true,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = slideUp ? const Offset(0.0, 0.1) : Offset.zero;
        var end = Offset.zero;
        var curve = pageTransitionCurve;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        
        var offsetAnimation = animation.drive(tween);
        var fadeAnimation = fadeIn ? animation : const AlwaysStoppedAnimation(1.0);

        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(
            position: offsetAnimation,
            child: child,
          ),
        );
      },
      transitionDuration: pageTransitionDuration,
      reverseTransitionDuration: pageTransitionDuration,
    );
  }
} 