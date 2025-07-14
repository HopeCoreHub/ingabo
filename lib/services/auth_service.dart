import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Registration result enum
enum RegistrationResult {
  success,
  emailAlreadyExists,
  error
}

// Email link result enum
enum EmailLinkResult {
  sent,
  invalidEmail,
  error
}

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  
  final Uuid _uuid = const Uuid();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isLoggedIn = false;
  String? _userId;
  String? _username;
  bool _isLoading = true;
  
  factory AuthService() {
    return _instance;
  }

  AuthService._internal() {
    _loadAuthState();
  }

  bool get isLoggedIn => _isLoggedIn;
  String? get userId => _userId;
  String? get username => _username;
  bool get isLoading => _isLoading;

  // Load auth state from SharedPreferences
  Future<void> _loadAuthState() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      _userId = prefs.getString('userId');
      _username = prefs.getString('username');
    } catch (e) {
      debugPrint('Error loading auth state: $e');
      _isLoggedIn = false;
      _userId = null;
      _username = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Hash password for security
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Get all users from SharedPreferences
  Future<List<Map<String, dynamic>>> _getUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString('users') ?? '[]';
    final List<dynamic> usersList = jsonDecode(usersJson);
    return usersList.cast<Map<String, dynamic>>();
  }
  
  // Public method to get users (for migration purposes)
  Future<List<Map<String, dynamic>>> getUsers() async {
    return await _getUsers();
  }

  // Save users to SharedPreferences
  Future<void> _saveUsers(List<Map<String, dynamic>> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('users', jsonEncode(users));
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Hash the password for comparison
      final hashedPassword = _hashPassword(password);
      
      // Get users from SharedPreferences
      final users = await _getUsers();
      
      // Find user with matching email
      final user = users.firstWhere(
        (user) => user['email'] == email,
        orElse: () => <String, dynamic>{},
      );
      
      // Check if user exists and password matches
      if (user.isEmpty || user['password'] != hashedPassword) {
        return false;
      }
      
      // User authenticated successfully
      _isLoggedIn = true;
      _userId = user['id'];
      _username = user['name'];
      
      // Save auth state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userId', _userId!);
      await prefs.setString('username', _username!);
      
      return true;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Send sign-in link to email
  Future<EmailLinkResult> sendSignInLinkToEmail(String email) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Validate email format
      if (!email.contains('@') || !email.contains('.')) {
        return EmailLinkResult.invalidEmail;
      }
      
      // Create action code settings for Firebase email link
      final actionCodeSettings = ActionCodeSettings(
        url: 'https://hopecore-hub.firebaseapp.com/?email=$email',
        // This must be true for email link sign-in
        handleCodeInApp: true,
        androidPackageName: 'com.example.ingabo',
        androidInstallApp: true,
        androidMinimumVersion: '12',
        iOSBundleId: 'com.example.ingabo',
      );
      
      // Send sign-in link to email using Firebase Auth
      await _auth.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: actionCodeSettings,
      );
      
      // Save the email locally to be used when the link is opened
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pendingEmailLink', email);
      
      debugPrint('Email sign-in link sent successfully to $email');
      return EmailLinkResult.sent;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase email link error: ${e.code}, ${e.message}');
      
      // Check specific Firebase Auth error codes
      if (e.code == 'invalid-email') {
        return EmailLinkResult.invalidEmail;
      }
      
      return EmailLinkResult.error;
    } catch (e) {
      debugPrint('Email link error: $e');
      return EmailLinkResult.error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // New method to handle sign-in with email link when the app is opened via the link
  Future<bool> signInWithEmailLink(String email, String link) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Check if the link is a sign-in link
      if (!_auth.isSignInWithEmailLink(link)) {
        debugPrint('Not a valid sign-in link');
        return false;
      }
      
      // Sign in with email link
      final userCredential = await _auth.signInWithEmailLink(
        email: email,
        emailLink: link,
      );
      
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        debugPrint('Sign in failed - no user returned');
        return false;
      }
      
      // User signed in successfully
      _isLoggedIn = true;
      _userId = firebaseUser.uid;
      _username = firebaseUser.displayName ?? email.split('@')[0];
      
      // Save auth state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userId', _userId!);
      await prefs.setString('username', _username!);
      
      // Clear the pending email
      await prefs.remove('pendingEmailLink');
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error signing in with email link: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<RegistrationResult> register(String name, String email, String password) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Get current users
      final users = await _getUsers();
      
      // Check if email already exists
      final emailExists = users.any((user) => user['email'] == email);
      if (emailExists) {
        return RegistrationResult.emailAlreadyExists; // Return special error code
      }
      
      // Hash the password
      final hashedPassword = _hashPassword(password);
      
      // Generate a new user ID
      final userId = _uuid.v4();
      
      // Create new user
      final newUser = {
        'id': userId,
        'name': name,
        'email': email,
        'password': hashedPassword,
        'createdAt': DateTime.now().toIso8601String(),
        'isGuest': false
      };
      
      // Add to users list and save
      users.add(newUser);
      await _saveUsers(users);
      
      // Set as logged in
      _isLoggedIn = true;
      _userId = userId;
      _username = name;
      
      // Save auth state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userId', _userId!);
      await prefs.setString('username', _username!);
      
      return RegistrationResult.success;
    } catch (e) {
      debugPrint('Registration error: $e');
      return RegistrationResult.error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Clear auth state from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('isLoggedIn');
      await prefs.remove('userId');
      await prefs.remove('username');
      
      // Update local state
      _isLoggedIn = false;
      _userId = null;
      _username = null;
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Securely store API key
  static Future<void> storeApiKey(String apiKey) async {
    final secureStorage = FlutterSecureStorage();
    await secureStorage.write(key: 'claude_api_key', value: apiKey);
  }

  // Retrieve API key securely
  static Future<String?> getApiKey() async {
    final secureStorage = FlutterSecureStorage();
    return await secureStorage.read(key: 'claude_api_key');
  }
} 