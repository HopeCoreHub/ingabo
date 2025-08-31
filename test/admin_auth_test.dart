import 'package:flutter_test/flutter_test.dart';
import 'package:ingabo/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Admin Authentication Tests', () {
    late AuthService authService;

    setUpAll(() async {
      // Mock Firebase for testing
      const MethodChannel channel = MethodChannel('plugins.flutter.io/firebase_core');
      channel.setMockMethodCallHandler((MethodCall methodCall) async {
        return <String, dynamic>{
          'name': '[DEFAULT]',
        };
      });
      
      // Mock Firebase Auth
      const MethodChannel authChannel = MethodChannel('plugins.flutter.io/firebase_auth');
      authChannel.setMockMethodCallHandler((MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'Auth#registerIdTokenListener':
          case 'Auth#registerAuthStateListener':
            return <String, dynamic>{
              'handle': 1,
            };
          case 'Auth#signInWithEmailAndPassword':
            // Simulate Firebase Auth failure to test local auth
            throw PlatformException(code: 'network-request-failed');
          default:
            return null;
        }
      });
    });

    setUp(() async {
      // Initialize SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
      authService = AuthService();
      
      // Wait a bit for auth service to initialize
      await Future.delayed(const Duration(milliseconds: 100));
    });

    test('should identify admin user correctly with local storage', () async {
      // Test admin credentials
      const adminEmail = 'info@ingabohopecore.com';
      const adminPassword = 'Hope2025!';
      
      // Login with admin credentials (will use local auth since Firebase is mocked to fail)
      final loginResult = await authService.login(adminEmail, adminPassword);
      
      // Verify login was successful
      expect(loginResult, true);
      expect(authService.isLoggedIn, true);
      expect(authService.username, 'Admin');
      
      // Check if user is identified as admin
      final isAdmin = await authService.isAdminAsync();
      expect(isAdmin, true);
      
      // Also test synchronous admin check
      expect(authService.isAdmin(), true);
    });

    test('should reject non-admin user for dashboard access', () async {
      // Test with non-admin credentials
      const userEmail = 'user@example.com';
      const userPassword = 'password123';
      
      // Register a regular user first
      final regResult = await authService.register('Test User', userEmail, userPassword);
      expect(regResult, RegistrationResult.success);
      
      // Logout first
      await authService.logout();
      
      // Login with user credentials
      final loginResult = await authService.login(userEmail, userPassword);
      
      // Verify login was successful
      expect(loginResult, true);
      expect(authService.isLoggedIn, true);
      
      // Check if user is NOT identified as admin
      final isAdmin = await authService.isAdminAsync();
      expect(isAdmin, false);
      
      // Check synchronous admin check
      expect(authService.isAdmin(), false);
    });

    test('should create admin user automatically on first admin login', () async {
      const adminEmail = 'info@ingabohopecore.com';
      const adminPassword = 'Hope2025!';
      
      // Login with admin credentials (should create admin user if not exists)
      final loginResult = await authService.login(adminEmail, adminPassword);
      
      // Verify admin user was created and logged in
      expect(loginResult, true);
      expect(authService.isLoggedIn, true);
      expect(authService.username, 'Admin');
      
      // Verify admin status
      final isAdmin = await authService.isAdminAsync();
      expect(isAdmin, true);
      
      // Check that admin user was added to local storage
      final users = await authService.getUsers();
      final adminUser = users.firstWhere(
        (user) => user['email'] == adminEmail,
        orElse: () => <String, dynamic>{},
      );
      
      expect(adminUser.isNotEmpty, true);
      expect(adminUser['isAdmin'], true);
      expect(adminUser['name'], 'Admin');
    });
  });
}