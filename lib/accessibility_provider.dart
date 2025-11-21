import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccessibilityProvider extends ChangeNotifier {
  // Font family settings
  String _fontFamily = 'Inter (Default)';
  static const List<String> supportedFontFamilies = [
    'Inter (Default)',
    'Roboto',
    'Open Sans',
    'Montserrat',
    'Lato',
  ];

  // Other accessibility settings
  bool _highContrastMode = false;
  bool _reduceMotion = false;
  bool _textToSpeech = false;
  bool _voiceToText = false;

  // Loading state
  bool _isLoading = true;

  // Firebase instance
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  AccessibilityProvider() {
    _loadAccessibilityPreferences();
  }

  // Getters
  String get fontFamily => _fontFamily;
  bool get highContrastMode => _highContrastMode;
  bool get reduceMotion => _reduceMotion;
  bool get textToSpeech => _textToSpeech;
  bool get voiceToText => _voiceToText;
  bool get isLoading => _isLoading;
  List<String> get fontFamilies => supportedFontFamilies;

  // Get actual font family name (without the "(Default)" suffix)
  String getActualFontFamily() {
    return _fontFamily.split(' ')[0];
  }

  Future<void> _loadAccessibilityPreferences() async {
    _isLoading = true;
    notifyListeners();

    try {
      // First try to get settings from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      _fontFamily = prefs.getString('fontFamily') ?? 'Inter (Default)';
      _highContrastMode = prefs.getBool('highContrastMode') ?? false;
      _reduceMotion = prefs.getBool('reduceMotion') ?? false;
      _textToSpeech = prefs.getBool('textToSpeech') ?? false;
      _voiceToText = prefs.getBool('voiceToText') ?? false;

      // Try to get the user ID from SharedPreferences
      final userId = prefs.getString('userId');

      // If user is logged in, try to get settings from Firebase
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

            if (settingsData.containsKey('accessibility')) {
              final accessibilityData =
                  settingsData['accessibility'] as Map<String, dynamic>;

              _fontFamily = accessibilityData['fontFamily'] ?? _fontFamily;
              _highContrastMode =
                  accessibilityData['highContrastMode'] ?? _highContrastMode;
              _reduceMotion =
                  accessibilityData['reduceMotion'] ?? _reduceMotion;
              _textToSpeech =
                  accessibilityData['textToSpeech'] ?? _textToSpeech;
              _voiceToText = accessibilityData['voiceToText'] ?? _voiceToText;
            }
          }
        } catch (e) {
          debugPrint('Error loading accessibility settings from Firebase: $e');
          // Continue with settings from SharedPreferences
        }
      }
    } catch (e) {
      debugPrint('Error loading accessibility preferences: $e');
      // Use defaults
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Set font family
  Future<void> setFontFamily(String fontFamily) async {
    if (!supportedFontFamilies.contains(fontFamily)) {
      return;
    }

    _fontFamily = fontFamily;
    notifyListeners();

    await _saveAccessibilitySettings();
  }

  // Toggle high contrast mode
  Future<void> toggleHighContrastMode(bool value) async {
    _highContrastMode = value;
    notifyListeners();

    await _saveAccessibilitySettings();
  }

  // Toggle reduce motion
  Future<void> toggleReduceMotion(bool value) async {
    _reduceMotion = value;
    notifyListeners();

    await _saveAccessibilitySettings();
  }

  // Toggle text-to-speech
  Future<void> toggleTextToSpeech(bool value) async {
    _textToSpeech = value;
    notifyListeners();

    await _saveAccessibilitySettings();
  }

  // Toggle voice-to-text
  Future<void> toggleVoiceToText(bool value) async {
    _voiceToText = value;
    notifyListeners();

    await _saveAccessibilitySettings();
  }

  // Save all accessibility settings
  Future<void> _saveAccessibilitySettings() async {
    try {
      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fontFamily', _fontFamily);
      await prefs.setBool('highContrastMode', _highContrastMode);
      await prefs.setBool('reduceMotion', _reduceMotion);
      await prefs.setBool('textToSpeech', _textToSpeech);
      await prefs.setBool('voiceToText', _voiceToText);

      // Try to save to Firebase if user is logged in
      final userId = prefs.getString('userId');

      if (userId != null) {
        try {
          await _db
              .collection('users')
              .doc(userId)
              .collection('settings')
              .doc('user_settings')
              .set({
                'accessibility': {
                  'fontFamily': _fontFamily,
                  'highContrastMode': _highContrastMode,
                  'reduceMotion': _reduceMotion,
                  'textToSpeech': _textToSpeech,
                  'voiceToText': _voiceToText,
                },
              }, SetOptions(merge: true));
        } catch (e) {
          debugPrint('Error saving accessibility settings to Firebase: $e');
          // Continue even if saving to Firebase fails
        }
      }
    } catch (e) {
      debugPrint('Error saving accessibility preferences: $e');
    }
  }
}
