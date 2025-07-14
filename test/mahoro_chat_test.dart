import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ingabo/mahoro_page.dart';
import 'package:ingabo/theme_provider.dart';
import 'package:ingabo/services/auth_service.dart';

// Simple mock for AuthService
class MockAuthService extends ChangeNotifier implements AuthService {
  @override
  bool get isLoggedIn => true;
  
  @override
  String? get userId => 'test-user-id';
  
  @override
  Future<bool> login(String email, String password) async => true;
  
  @override
  Future<bool> register(String email, String password, String name) async => true;
  
  @override
  Future<void> logout() async {}
  
  @override
  Future<List<Map<String, dynamic>>> getUsers() async => [];
  
  @override
  Future<void> updateUserProfile(Map<String, dynamic> userData) async {}
  
  @override
  Future<Map<String, dynamic>?> getUserProfile() async => {'name': 'Test User'};
  
  @override
  Future<void> deleteAccount() async {}
  
  @override
  Future<void> resetPassword(String email) async {}
  
  @override
  Future<void> updateEmail(String newEmail, String password) async {}
  
  @override
  Future<void> updatePassword(String currentPassword, String newPassword) async {}
  
  @override
  Future<void> verifyEmail() async {}
  
  // Static methods for API key management
  static Future<String?> getApiKey() async {
    return 'test-api-key';
  }
  
  static Future<void> storeApiKey(String apiKey) async {
    // Do nothing in test
  }
}

void main() {
  // Override the AuthService static methods for testing
  AuthService.getApiKey = MockAuthService.getApiKey;
  AuthService.storeApiKey = MockAuthService.storeApiKey;
  
  testWidgets('Mahoro chat simulation responds with appropriate messages', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider<AuthService>(create: (_) => MockAuthService()),
        ],
        child: const MaterialApp(
          home: MahoroPage(),
        ),
      ),
    );

    // Wait for the initial UI to build
    await tester.pumpAndSettle();

    // Verify that the welcome message is displayed
    expect(find.text("Muraho! I'm Mahoro, your supportive AI companion. How can I help you today? You can speak to me in Kinyarwanda, English, Swahili, or French."), findsOneWidget);

    // Enter a test message
    await tester.enterText(find.byType(TextField), 'Hello');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    
    // Wait for the typing indicator and response
    await tester.pump();
    
    // Wait for the simulated delay (2 seconds)
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    
    // Verify that the user message was added
    expect(find.text('Hello'), findsOneWidget);
    
    // Verify that the AI response was added (English response)
    expect(find.text("Thank you for sharing. I understand how you feel and I'm here to listen. Would you like to tell me more about what's on your mind?"), findsOneWidget);
    
    print('All Mahoro chat simulation tests passed successfully!');
  });
} 