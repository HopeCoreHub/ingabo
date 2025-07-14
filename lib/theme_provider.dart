import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = true;
  bool _isLoading = true;
  
  static const Duration animationDurationShort = Duration(milliseconds: 200);
  static const Duration animationDurationMedium = Duration(milliseconds: 300);
  static const Duration animationDurationLong = Duration(milliseconds: 500);
  static const Duration pageTransitionDuration = Duration(milliseconds: 300);
  static const Curve animationCurveDefault = Curves.easeInOut;
  static const Curve pageTransitionCurve = Curves.easeInOutCubic;
  static const Curve animationCurveFast = Curves.easeOut;
  static const Curve animationCurveSnappy = Curves.elasticOut;
  static const Duration staggerInterval = Duration(milliseconds: 50);
  
  // Firebase instance
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  ThemeProvider() {
    _loadThemePreference();
  }

  bool get isDarkMode => _isDarkMode;
  bool get isLoading => _isLoading;
  
  Future<void> _loadThemePreference() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // First try to get the theme from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool('isDarkMode') ?? true;
      
      // Try to get the user ID from SharedPreferences
      final userId = prefs.getString('userId');
      
      // If user is logged in, try to get theme from Firebase
      if (userId != null) {
        try {
          final userSettings = await _db.collection('users')
            .doc(userId)
            .collection('settings')
            .doc('user_settings')
            .get();
          
          if (userSettings.exists && userSettings.data() != null) {
            final settingsData = userSettings.data()!;
            
            if (settingsData.containsKey('appearance') &&
                settingsData['appearance'] is Map &&
                settingsData['appearance'].containsKey('isDarkMode')) {
              _isDarkMode = settingsData['appearance']['isDarkMode'] as bool;
            }
          }
        } catch (e) {
          debugPrint('Error loading theme from Firebase: $e');
          // Continue with theme from SharedPreferences
        }
      }
    } catch (e) {
      debugPrint('Error loading theme: $e');
      _isDarkMode = true; // Default to dark mode
    } finally {
      _isLoading = false;
    notifyListeners();
  }
  }
  
  Future<void> toggleDarkMode(bool value) async {
    _isDarkMode = value;
    notifyListeners();

    try {
      // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkMode', value);
      
      // Try to save to Firebase if user is logged in
      final userId = prefs.getString('userId');
      
      if (userId != null) {
        try {
          await _db.collection('users')
            .doc(userId)
            .collection('settings')
            .doc('user_settings')
            .set({
              'appearance': {
                'isDarkMode': value
              }
            }, SetOptions(merge: true));
        } catch (e) {
          debugPrint('Error saving theme to Firebase: $e');
          // Continue even if saving to Firebase fails
    }
  }
    } catch (e) {
      debugPrint('Error saving theme: $e');
    }
  }
  
  ThemeData getTheme(BuildContext context) {
    if (_isDarkMode) {
      return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: const Color(0xFF111827),
      primaryColor: const Color(0xFF8A4FFF),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF8A4FFF),
          secondary: const Color(0xFFA855F7),
          background: const Color(0xFF111827),
          surface: const Color(0xFF1E293B),
        ),
      appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E293B),
        elevation: 0,
      ),
        textTheme: Theme.of(context).textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1E293B),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
      ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF8A4FFF),
              width: 2,
            ),
          ),
        ),
      );
    } else {
      return ThemeData.light().copyWith(
      scaffoldBackgroundColor: Colors.white,
      primaryColor: const Color(0xFFE53935),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFFE53935),
          secondary: Color(0xFFE53935),
        background: Colors.white,
        surface: Color(0xFFF1F5F9),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
      ),
        textTheme: Theme.of(context).textTheme.apply(
          bodyColor: Colors.black87,
          displayColor: Colors.black87,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF1F5F9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFFE53935),
              width: 2,
            ),
          ),
      ),
    );
  }
  }
} 