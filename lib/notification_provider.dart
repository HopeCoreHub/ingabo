import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationProvider extends ChangeNotifier {
  // Notification settings
  bool _forumReplies = true;
  bool _weeklyCheckIns = true;
  bool _systemUpdates = false;

  // Loading state
  bool _isLoading = true;

  // Firebase instance
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  NotificationProvider() {
    _loadNotificationPreferences();
  }

  // Getters
  bool get forumReplies => _forumReplies;
  bool get weeklyCheckIns => _weeklyCheckIns;
  bool get systemUpdates => _systemUpdates;
  bool get isLoading => _isLoading;

  Future<void> _loadNotificationPreferences() async {
    _isLoading = true;
    notifyListeners();

    try {
      // First try to get settings from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      _forumReplies = prefs.getBool('forumReplies') ?? true;
      _weeklyCheckIns = prefs.getBool('weeklyCheckIns') ?? true;
      _systemUpdates = prefs.getBool('systemUpdates') ?? false;

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

            if (settingsData.containsKey('notifications')) {
              final notificationData =
                  settingsData['notifications'] as Map<String, dynamic>;

              _forumReplies = notificationData['forumReplies'] ?? _forumReplies;
              _weeklyCheckIns =
                  notificationData['weeklyCheckIns'] ?? _weeklyCheckIns;
              _systemUpdates =
                  notificationData['systemUpdates'] ?? _systemUpdates;
            }
          }
        } catch (e) {
          debugPrint('Error loading notification settings from Firebase: $e');
          // Continue with settings from SharedPreferences
        }
      }
    } catch (e) {
      debugPrint('Error loading notification preferences: $e');
      // Use defaults
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Toggle forum replies notifications
  Future<void> toggleForumReplies(bool value) async {
    _forumReplies = value;
    notifyListeners();

    await _saveNotificationSettings();
  }

  // Toggle weekly check-ins notifications
  Future<void> toggleWeeklyCheckIns(bool value) async {
    _weeklyCheckIns = value;
    notifyListeners();

    await _saveNotificationSettings();
  }

  // Toggle system updates notifications
  Future<void> toggleSystemUpdates(bool value) async {
    _systemUpdates = value;
    notifyListeners();

    await _saveNotificationSettings();
  }

  // Save all notification settings
  Future<void> _saveNotificationSettings() async {
    try {
      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('forumReplies', _forumReplies);
      await prefs.setBool('weeklyCheckIns', _weeklyCheckIns);
      await prefs.setBool('systemUpdates', _systemUpdates);

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
                'notifications': {
                  'forumReplies': _forumReplies,
                  'weeklyCheckIns': _weeklyCheckIns,
                  'systemUpdates': _systemUpdates,
                },
              }, SetOptions(merge: true));
        } catch (e) {
          debugPrint('Error saving notification settings to Firebase: $e');
          // Continue even if saving to Firebase fails
        }
      }
    } catch (e) {
      debugPrint('Error saving notification preferences: $e');
    }
  }
}
