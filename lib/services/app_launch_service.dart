import 'package:shared_preferences/shared_preferences.dart';

/// Manages app launch experience flags such as onboarding and in-app tours.
class AppLaunchService {
  static const String _onboardingKey = 'has_seen_onboarding_v2';
  static const String _tourKey = 'has_completed_app_tour_v1';

  /// Returns true if the onboarding experience has been completed.
  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  /// Marks the onboarding experience as completed.
  static Future<void> markOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  /// Returns true if the app tour has already been completed.
  static Future<bool> hasCompletedAppTour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_tourKey) ?? false;
  }

  /// Marks the in-app tour as completed.
  static Future<void> markAppTourComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tourKey, true);
  }
}
