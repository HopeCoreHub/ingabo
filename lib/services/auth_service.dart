import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Registration result enum
enum RegistrationResult {
  success,
  emailAlreadyExists,
  error
}

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  
  final Uuid _uuid = const Uuid();
  
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