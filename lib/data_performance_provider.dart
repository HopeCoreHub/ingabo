import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DataPerformanceProvider extends ChangeNotifier {
  // Data and performance settings
  bool _lowDataMode = false;
  bool _imageLazyLoading = false;
  bool _offlineMode = false;
  
  // Loading state
  bool _isLoading = true;
  
  // Firebase instance
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DataPerformanceProvider() {
    _loadDataPerformancePreferences();
  }

  // Getters
  bool get lowDataMode => _lowDataMode;
  bool get imageLazyLoading => _imageLazyLoading;
  bool get offlineMode => _offlineMode;
  bool get isLoading => _isLoading;
  
  Future<void> _loadDataPerformancePreferences() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // First try to get settings from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      _lowDataMode = prefs.getBool('lowDataMode') ?? false;
      _imageLazyLoading = prefs.getBool('imageLazyLoading') ?? false;
      _offlineMode = prefs.getBool('offlineMode') ?? false;
      
      // Try to get the user ID from SharedPreferences
      final userId = prefs.getString('userId');
      
      // If user is logged in, try to get settings from Firebase
      if (userId != null) {
        try {
          final userSettings = await _db.collection('users')
            .doc(userId)
            .collection('settings')
            .doc('user_settings')
            .get();
          
          if (userSettings.exists && userSettings.data() != null) {
            final settingsData = userSettings.data()!;
            
            if (settingsData.containsKey('dataPerformance')) {
              final dataPerformanceData = settingsData['dataPerformance'] as Map<String, dynamic>;
              
              _lowDataMode = dataPerformanceData['lowDataMode'] ?? _lowDataMode;
              _imageLazyLoading = dataPerformanceData['imageLazyLoading'] ?? _imageLazyLoading;
              _offlineMode = dataPerformanceData['offlineMode'] ?? _offlineMode;
            }
          }
        } catch (e) {
          debugPrint('Error loading data performance settings from Firebase: $e');
          // Continue with settings from SharedPreferences
        }
      }
    } catch (e) {
      debugPrint('Error loading data performance preferences: $e');
      // Use defaults
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Toggle low data mode
  Future<void> toggleLowDataMode(bool value) async {
    _lowDataMode = value;
    notifyListeners();
    
    await _saveDataPerformanceSettings();
  }
  
  // Toggle image lazy loading
  Future<void> toggleImageLazyLoading(bool value) async {
    _imageLazyLoading = value;
    notifyListeners();
    
    await _saveDataPerformanceSettings();
  }
  
  // Toggle offline mode
  Future<void> toggleOfflineMode(bool value) async {
    _offlineMode = value;
    notifyListeners();
    
    await _saveDataPerformanceSettings();
  }
  
  // Save all data performance settings
  Future<void> _saveDataPerformanceSettings() async {
    try {
      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('lowDataMode', _lowDataMode);
      await prefs.setBool('imageLazyLoading', _imageLazyLoading);
      await prefs.setBool('offlineMode', _offlineMode);
      
      // Try to save to Firebase if user is logged in
      final userId = prefs.getString('userId');
      
      if (userId != null) {
        try {
          await _db.collection('users')
            .doc(userId)
            .collection('settings')
            .doc('user_settings')
            .set({
              'dataPerformance': {
                'lowDataMode': _lowDataMode,
                'imageLazyLoading': _imageLazyLoading,
                'offlineMode': _offlineMode,
              }
            }, SetOptions(merge: true));
        } catch (e) {
          debugPrint('Error saving data performance settings to Firebase: $e');
          // Continue even if saving to Firebase fails
        }
      }
    } catch (e) {
      debugPrint('Error saving data performance preferences: $e');
    }
  }
} 