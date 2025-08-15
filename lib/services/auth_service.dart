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
  bool _isEmailVerified = false;
  
  factory AuthService() {
    return _instance;
  }

  AuthService._internal() {
    _loadAuthState();
    // Listen for Firebase auth state changes
    _auth.authStateChanges().listen((User? user) {
      _syncFirebaseAuthState(user);
    });
  }

  bool get isLoggedIn => _isLoggedIn;
  String? get userId => _userId;
  String? get username => _username;
  bool get isLoading => _isLoading;
  bool get isEmailVerified => _isEmailVerified;

  // Sync Firebase auth state with local auth state
  Future<void> _syncFirebaseAuthState(User? user) async {
    if (user != null) {
      _isLoggedIn = true;
      _userId = user.uid;
      _username = user.displayName ?? user.email?.split('@')[0] ?? 'User';
      _isEmailVerified = user.emailVerified;
      
      // Update SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userId', _userId!);
      await prefs.setString('username', _username!);
      await prefs.setBool('isEmailVerified', _isEmailVerified);
    } else {
      // Don't automatically log out if Firebase user is null
      // We might be using local auth only
    }
    notifyListeners();
  }
  
  // Public method to force-update the authentication state
  Future<void> updateAuthState(bool isLoggedIn, String userId, String username) async {
    _isLoggedIn = isLoggedIn;
    _userId = userId;
    _username = username;
    
    // Update SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', isLoggedIn);
    
    if (isLoggedIn) {
      await prefs.setString('userId', userId);
      await prefs.setString('username', username);
      debugPrint('Auth state manually updated: User $username logged in');
    } else {
      await prefs.remove('userId');
      await prefs.remove('username');
      await prefs.remove('isEmailVerified');
      debugPrint('Auth state manually updated: User logged out');
    }
    
    notifyListeners();
  }
  
  // Method to reload auth state from SharedPreferences and Firebase
  Future<void> reloadAuthState() async {
    debugPrint('Reloading auth state...');
    
    try {
      // First check SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final storedIsLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      
      if (storedIsLoggedIn) {
        final storedUserId = prefs.getString('userId');
        final storedUsername = prefs.getString('username');
        
        if (storedUserId != null && storedUsername != null) {
          // We have stored credentials - update state if not already logged in
          if (!_isLoggedIn || _userId != storedUserId) {
            _isLoggedIn = true;
            _userId = storedUserId;
            _username = storedUsername;
            _isEmailVerified = prefs.getBool('isEmailVerified') ?? false;
            
            debugPrint('Auth state reloaded: User $_username logged in from SharedPreferences');
            notifyListeners();
          }
        }
      }
      
      // Then check Firebase
      final firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        await firebaseUser.reload();
        _isLoggedIn = true;
        _userId = firebaseUser.uid;
        _username = firebaseUser.displayName ?? firebaseUser.email?.split('@')[0] ?? 'User';
        _isEmailVerified = firebaseUser.emailVerified;
        
        // Update SharedPreferences with Firebase values
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userId', _userId!);
        await prefs.setString('username', _username!);
        await prefs.setBool('isEmailVerified', _isEmailVerified);
        
        debugPrint('Auth state reloaded: User $_username logged in from Firebase');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error reloading auth state: $e');
    }
  }

  // Load auth state from SharedPreferences
  Future<void> _loadAuthState() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      _userId = prefs.getString('userId');
      _username = prefs.getString('username');
      _isEmailVerified = prefs.getBool('isEmailVerified') ?? false;
      
      // Try to sync with Firebase if we're logged in
      if (_isLoggedIn) {
        final firebaseUser = _auth.currentUser;
        if (firebaseUser != null) {
          _isEmailVerified = firebaseUser.emailVerified;
          // Update SharedPreferences with latest email verification status
          await prefs.setBool('isEmailVerified', _isEmailVerified);
        }
      }
    } catch (e) {
      debugPrint('Error loading auth state: $e');
      _isLoggedIn = false;
      _userId = null;
      _username = null;
      _isEmailVerified = false;
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
      // First try Firebase login
      try {
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: email, 
          password: password
        );
        
        final firebaseUser = userCredential.user;
        if (firebaseUser != null) {
          // Firebase login successful
          _isLoggedIn = true;
          _userId = firebaseUser.uid;
          _username = firebaseUser.displayName ?? email.split('@')[0];
          _isEmailVerified = firebaseUser.emailVerified;
          
          // Save auth state
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('userId', _userId!);
          await prefs.setString('username', _username!);
          await prefs.setBool('isEmailVerified', _isEmailVerified);
          
          notifyListeners();
          return true;
        }
      } on FirebaseAuthException catch (e) {
        // Handle specific Firebase errors
        if (e.code == 'too-many-requests') {
          debugPrint('Firebase rate limiting detected (too many login attempts)');
          // We'll continue to local login below
        } else {
          debugPrint('Firebase login error: ${e.code}, ${e.message}');
        }
        // Continue to try local login if Firebase login fails
      } catch (firebaseError) {
        debugPrint('Firebase login error: $firebaseError');
        // Continue to try local login if Firebase login fails
      }
      
      // If Firebase login fails, try local login
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
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Send verification email to the current user
  Future<Map<String, dynamic>> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        return {'success': true, 'error': null};
      }
      return {'success': false, 'error': 'No user logged in or email already verified'};
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase error sending verification email: ${e.code}, ${e.message}');
      String errorMsg;
      
      if (e.code == 'too-many-requests') {
        errorMsg = 'Too many attempts. Please try again after some time.';
      } else {
        errorMsg = 'Failed to send verification email: ${e.message}';
      }
      
      return {'success': false, 'error': errorMsg, 'code': e.code};
    } catch (e) {
      debugPrint('Error sending verification email: $e');
      return {'success': false, 'error': 'An unexpected error occurred'};
    }
  }
  
  // Check if the current user's email is verified
  Future<bool> checkEmailVerified() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Reload user to get latest verification status
        await user.reload();
        final reloadedUser = _auth.currentUser;
        if (reloadedUser != null) {
          _isEmailVerified = reloadedUser.emailVerified;
          
          // Update SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isEmailVerified', _isEmailVerified);
          
          notifyListeners();
          return _isEmailVerified;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error checking email verification: $e');
      return false;
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
        androidPackageName: 'com.ingabohopecore.hopecorehub',
        androidInstallApp: true,
        androidMinimumVersion: '12',
        iOSBundleId: 'com.ingabohopecore.hopecorehub',
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
      _isEmailVerified = firebaseUser.emailVerified;
      
      // Save auth state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userId', _userId!);
      await prefs.setString('username', _username!);
      await prefs.setBool('isEmailVerified', _isEmailVerified);
      
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
      // First try to register with Firebase
      bool shouldUseLocalRegistration = false;
      
      try {
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password
        );
        
        final firebaseUser = userCredential.user;
        if (firebaseUser != null) {
          // Update user profile
          await firebaseUser.updateDisplayName(name);
          
          try {
            // Send email verification (with error handling)
            await firebaseUser.sendEmailVerification();
          } catch (verificationError) {
            // Log but continue if verification sending fails
            debugPrint('Warning: Could not send verification email: $verificationError');
          }
          
          // User registered successfully with Firebase
          _isLoggedIn = true;
          _userId = firebaseUser.uid;
          _username = name;
          _isEmailVerified = false; // New users need to verify email
          
          // Save auth state
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('userId', _userId!);
          await prefs.setString('username', _username!);
          await prefs.setBool('isEmailVerified', _isEmailVerified);
          
          notifyListeners();
          return RegistrationResult.success;
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          return RegistrationResult.emailAlreadyExists;
        } else if (e.code == 'too-many-requests') {
          // Firebase is rate limiting us, fall back to local auth
          debugPrint('Firebase rate limiting detected, falling back to local authentication');
          shouldUseLocalRegistration = true;
        } else {
          // Continue with local registration for other Firebase errors
          debugPrint('Firebase registration failed: ${e.code}, ${e.message}');
          shouldUseLocalRegistration = true;
        }
      } catch (e) {
        // Generic error handling
        debugPrint('Error during Firebase registration: $e');
        shouldUseLocalRegistration = true;
      }
      
      // If we hit rate limiting or another Firebase error, 
      // use local registration as backup
      if (shouldUseLocalRegistration) {
        // Continue with local registration
      }
      
      // If Firebase registration fails, try local registration
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
      
      notifyListeners();
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
      // Sign out from Firebase
      await _auth.signOut();
      
      // Clear auth state from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('isLoggedIn');
      await prefs.remove('userId');
      await prefs.remove('username');
      await prefs.remove('isEmailVerified');
      
      // Update local state
      _isLoggedIn = false;
      _userId = null;
      _username = null;
      _isEmailVerified = false;
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