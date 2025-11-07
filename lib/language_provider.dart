import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LanguageProvider extends ChangeNotifier {
  String _currentLanguage = 'English';
  bool _isLoading = true;

  // Available languages
  static const List<String> supportedLanguages = [
    'English',
    'French',
    'Swahili',
    'Kinyarwanda',
  ];

  // Firebase instance
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  LanguageProvider() {
    _loadLanguagePreference();
  }

  String get currentLanguage => _currentLanguage;
  bool get isLoading => _isLoading;
  List<String> get languages => supportedLanguages;

  Future<void> _loadLanguagePreference() async {
    _isLoading = true;
    notifyListeners();

    try {
      // First try to get the language from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      _currentLanguage = prefs.getString('appLanguage') ?? 'English';

      // Try to get the user ID from SharedPreferences
      final userId = prefs.getString('userId');

      // If user is logged in, try to get language from Firebase
      if (userId != null) {
        try {
          final userSettings =
              await _db
                  .collection('users')
                  .doc(userId)
                  .collection('settings')
                  .doc('user_settings')
                  .get();

          if (userSettings.exists && userSettings.data() != null) {
            final settingsData = userSettings.data()!;

            if (settingsData.containsKey('language') &&
                settingsData['language'] is String) {
              _currentLanguage = settingsData['language'] as String;
            }
          }
        } catch (e) {
          debugPrint('Error loading language from Firebase: $e');
          // Continue with language from SharedPreferences
        }
      }
    } catch (e) {
      debugPrint('Error loading language preference: $e');
      _currentLanguage = 'English'; // Default to English
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setLanguage(String language) async {
    if (!supportedLanguages.contains(language)) {
      return;
    }

    _currentLanguage = language;
    notifyListeners();

    try {
      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('appLanguage', language);

      // Try to save to Firebase if user is logged in
      final userId = prefs.getString('userId');

      if (userId != null) {
        try {
          await _db
              .collection('users')
              .doc(userId)
              .collection('settings')
              .doc('user_settings')
              .set({'language': language}, SetOptions(merge: true));
        } catch (e) {
          debugPrint('Error saving language to Firebase: $e');
          // Continue even if saving to Firebase fails
        }
      }
    } catch (e) {
      debugPrint('Error saving language preference: $e');
    }
  }

  // Get language display name in the current language (for future translations)
  String getLanguageDisplayName(String language) {
    // In the future, this could return translated language names
    return language;
  }
}
