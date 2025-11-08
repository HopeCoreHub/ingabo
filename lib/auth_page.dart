import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'services/auth_service.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

// Import main.dart to access MainNavigationWrapper and HopeCoreHub
import 'main.dart';

// User data class to store user information
class UserData {
  final String id;
  final String name;
  final String email;
  final String password;
  final DateTime createdAt;
  final bool isEmailLink;
  Map<String, dynamic> additionalData;

  UserData({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.createdAt,
    this.isEmailLink = false,
    this.additionalData = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'createdAt': createdAt.toIso8601String(),
      'isEmailLink': isEmailLink,
      'additionalData': additionalData,
    };
  }

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      password: json['password'],
      createdAt: DateTime.parse(json['createdAt']),
      isEmailLink: json['isEmailLink'] ?? false,
      additionalData: json['additionalData'] ?? {},
    );
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  // Static user storage
  static List<UserData> users = [];
  static const _uuid = Uuid();

  // Initialize users from SharedPreferences
  static Future<void> loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString('local_users');
    if (usersJson != null) {
      final List<dynamic> usersList = jsonDecode(usersJson);
      users = usersList.map((json) => UserData.fromJson(json)).toList();
    }
  }

  // Save users to SharedPreferences
  static Future<void> saveUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = jsonEncode(users.map((user) => user.toJson()).toList());
    await prefs.setString('local_users', usersJson);
  }

  // Add a new user
  static Future<UserData> addUser({
    required String name,
    required String email,
    required String password,
    bool isEmailLink = false,
    Map<String, dynamic> additionalData = const {},
  }) async {
    // Check if user with email already exists
    if (users.any((user) => user.email == email)) {
      throw Exception('Email already registered');
    }

    final newUser = UserData(
      id: _uuid.v4(),
      name: name,
      email: email,
      password: password, // In a real app, should be hashed
      createdAt: DateTime.now(),
      isEmailLink: isEmailLink,
      additionalData: additionalData,
    );

    users.add(newUser);
    await saveUsers();
    return newUser;
  }

  // Find user by email
  static UserData? findUserByEmail(String email) {
    try {
      return users.firstWhere((user) => user.email == email);
    } catch (e) {
      return null;
    }
  }

  // Update user data
  static Future<void> updateUser(UserData updatedUser) async {
    final index = users.indexWhere((user) => user.id == updatedUser.id);
    if (index != -1) {
      users[index] = updatedUser;
      await saveUsers();
    }
  }

  // Delete user
  static Future<void> deleteUser(String userId) async {
    users.removeWhere((user) => user.id == userId);
    await saveUsers();
  }

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage>
    with SingleTickerProviderStateMixin {
  bool _isLogin = true;
  bool _isPasswordless = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  bool _emailLinkSent = false;
  final Color accentColor = const Color(
    0xFF8A4FFF,
  ); // Added accent color definition

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();

    // Initialize local users storage
    AuthPage.loadUsers();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
      _errorMessage = null;
      _emailLinkSent = false;
      _animationController.reset();
      _animationController.forward();
    });
  }

  void _togglePasswordlessMode() {
    setState(() {
      _isPasswordless = !_isPasswordless;
      _errorMessage = null;
      _emailLinkSent = false;
      _animationController.reset();
      _animationController.forward();
    });
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
        _errorMessage = null;
      });

      final authService = Provider.of<AuthService>(context, listen: false);

      try {
        if (_isPasswordless) {
          // Handle passwordless email link sign-in
          final email = _emailController.text.trim();

          // Store user in local storage if they don't exist
          if (AuthPage.findUserByEmail(email) == null) {
            await AuthPage.addUser(
              name: email.split('@')[0],
              email: email,
              password: '',
              isEmailLink: true,
            );
          }

          final result = await authService.sendSignInLinkToEmail(email);

          switch (result) {
            case EmailLinkResult.sent:
              setState(() {
                _emailLinkSent = true;
              });
              break;
            case EmailLinkResult.invalidEmail:
              setState(() {
                _errorMessage = "Please enter a valid email address.";
              });
              break;
            case EmailLinkResult.error:
              setState(() {
                _errorMessage =
                    "Failed to send sign-in link. Please try again.";
              });
              break;
          }
        } else if (_isLogin) {
          // First check local storage
          final user = AuthPage.findUserByEmail(_emailController.text.trim());
          bool localSuccess = false;

          if (user != null &&
              user.password == _passwordController.text.trim()) {
            localSuccess = true;
            // Update login state locally and in AuthService
            if (mounted) {
              // Make sure auth service is updated
              final authService = Provider.of<AuthService>(
                context,
                listen: false,
              );
              // Force authentication state update
              authService.updateAuthState(true, user.id, user.name);

              _showSuccessMessage('Login successful!');
              // Navigate to home page with bottom navigation
              _navigateToHome();
            }
          }

          // If local login fails or no local user, try Firebase
          if (!localSuccess) {
            final success = await authService.login(
              _emailController.text.trim(),
              _passwordController.text.trim(),
            );

            if (!success) {
              setState(() {
                _errorMessage = "Invalid email or password. Please try again.";
              });
            } else if (mounted) {
              // Force a reload to ensure we get the latest auth state
              await authService.checkEmailVerified();

              // Wait a bit for state to update
              await Future.delayed(Duration(milliseconds: 100));

              _showSuccessMessage('Login successful!');
              // Navigate to home page with bottom navigation
              _navigateToHome();
            }
          }
        } else {
          // Handle registration
          try {
            // Add user to local storage
            await AuthPage.addUser(
              name: _nameController.text.trim(),
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            );

            // Also register with Firebase
            final result = await authService.register(
              _nameController.text.trim(),
              _emailController.text.trim(),
              _passwordController.text.trim(),
            );

            switch (result) {
              case RegistrationResult.success:
                if (mounted) {
                  // Show verification message if the account was created with Firebase
                  if (!authService.isEmailVerified) {
                    _showVerificationDialog();
                  } else {
                    _showSuccessMessage('Account created successfully!');
                    // Navigate to home page with bottom navigation
                    _navigateToHome();
                  }
                }
                break;
              case RegistrationResult.emailAlreadyExists:
                setState(() {
                  _errorMessage =
                      "This email is already registered. Please login instead.";
                  // Optionally switch to login mode
                  _isLogin = true;
                  _animationController.reset();
                  _animationController.forward();
                });
                break;
              case RegistrationResult.error:
                setState(() {
                  _errorMessage = "Registration failed. Please try again.";
                });
                break;
            }
          } catch (e) {
            setState(() {
              _errorMessage = e.toString();
            });
          }
        }
      } catch (e) {
        if (mounted) {
          String errorMessage = "An error occurred. Please try again.";

          if (e.toString().contains('email-already-in-use')) {
            errorMessage = "This email is already registered.";
          } else if (e.toString().contains('invalid-email')) {
            errorMessage = "The email address is not valid.";
          } else if (e.toString().contains('user-disabled')) {
            errorMessage = "This account has been disabled.";
          } else if (e.toString().contains('user-not-found') ||
              e.toString().contains('wrong-password')) {
            errorMessage = "Invalid email or password.";
          } else if (e.toString().contains('weak-password')) {
            errorMessage = "The password is too weak.";
          } else if (e.toString().contains('network-request-failed')) {
            errorMessage = "Network error. Please check your connection.";
          } else if (e.toString().contains('too-many-requests')) {
            errorMessage = "Too many attempts. Please try again later.";
          }

          setState(() {
            _errorMessage = errorMessage;
          });
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }

  // Function to navigate to home with bottom navigation bar
  void _navigateToHome() {
    // Replace the entire navigation stack with the home page wrapped in MainNavigationWrapper
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder:
            (context) => const MainNavigationWrapper(
              selectedIndex: 0,
              child: HopeCoreHub(),
            ),
      ),
      (route) => false, // Remove all previous routes
    );
  }

  // Show dialog for email verification after registration
  void _showVerificationDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8A4FFF).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.email_outlined,
                    color: const Color(0xFF8A4FFF),
                    size: 30,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Verify Your Email',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'A verification link has been sent to your email address. Please check your inbox and click the link to verify your account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Didn\'t receive an email?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () async {
                    final authService = Provider.of<AuthService>(
                      context,
                      listen: false,
                    );
                    final messenger = ScaffoldMessenger.of(context);
                    final result = await authService.sendEmailVerification();

                    if (!context.mounted) return;
                    if (result['success']) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Verification email sent again!'),
                          backgroundColor: const Color(0xFF8A4FFF),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } else {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            result['error'] ??
                                'Failed to send verification email',
                          ),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );

                      // If it's a rate limiting error, show additional guidance
                      if (result['code'] == 'too-many-requests') {
                        // Wait a moment before showing the second message
                        await Future.delayed(Duration(milliseconds: 300));

                        if (!context.mounted) return;
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              'Please check your email for an existing verification link or try again later',
                            ),
                            backgroundColor: Colors.orange,
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 6),
                          ),
                        );
                      }
                    }
                  },
                  child: Text(
                    'Resend Verification Email',
                    style: TextStyle(
                      color: const Color(0xFF8A4FFF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      // Navigate to home page with bottom navigation
                      _navigateToHome();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8A4FFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Continue',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF8A4FFF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final accentColor =
        isDarkMode ? const Color(0xFF8A4FFF) : const Color(0xFFE53935);

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      body: Stack(
        children: [
          _buildBackgroundDecoration(isDarkMode),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          _buildHeader(isDarkMode),
                          const SizedBox(height: 30),
                          _buildAuthToggle(accentColor),
                          const SizedBox(height: 24),
                          if (_errorMessage != null) _buildErrorMessage(),
                          if (_emailLinkSent) _buildEmailLinkSentMessage(),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child:
                                _isPasswordless
                                    ? _buildPasswordlessFields()
                                    : _isLogin
                                    ? _buildLoginFields()
                                    : _buildRegisterFields(),
                          ),
                          const SizedBox(height: 24),
                          _buildSubmitButton(),
                          const SizedBox(height: 16),
                          _buildPasswordlessToggle(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailLinkSentMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sign-in link sent!',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Check your email and click the link to sign in.',
                  style: TextStyle(color: Colors.green),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordlessFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email Address',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        _buildEmailField(),
      ],
    );
  }

  Widget _buildLoginFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email Address',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        _buildEmailField(),
        const SizedBox(height: 16),
        Text(
          'Password',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        _buildPasswordField(),
      ],
    );
  }

  Widget _buildRegisterFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Full Name',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        _buildNameField(),
        const SizedBox(height: 16),
        Text(
          'Email Address',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        _buildEmailField(),
        const SizedBox(height: 16),
        Text(
          'Password',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        _buildPasswordField(),
      ],
    );
  }

  Widget _buildPasswordlessToggle() {
    return TextButton(
      onPressed: _togglePasswordlessMode,
      child: Text(
        _isPasswordless
            ? 'Use password to sign in'
            : 'Sign in with email link (no password)',
        style: TextStyle(
          color:
              Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF8A4FFF)
                  : const Color(0xFFE53935),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      autocorrect: false,
      style: TextStyle(
        color:
            Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: 'Email Address',
        labelStyle: TextStyle(
          color:
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.white70
                  : Colors.black54,
        ),
        prefixIcon: Icon(
          Icons.email_outlined,
          color:
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.white54
                  : Colors.black38,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.white30
                    : Colors.black12,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.white30
                    : Colors.black12,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.white54
                    : Colors.black38,
            width: 2,
          ),
        ),
        filled: true,
        fillColor:
            Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1E293B)
                : const Color(0xFFF1F5F9),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your email';
        }
        if (!value.contains('@') || !value.contains('.')) {
          return 'Please enter a valid email address';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: TextStyle(
        color:
            Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: 'Password',
        labelStyle: TextStyle(
          color:
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.white70
                  : Colors.black54,
        ),
        prefixIcon: Icon(
          Icons.lock_outline,
          color:
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.white54
                  : Colors.black38,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.white54
                    : Colors.black38,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.white30
                    : Colors.black12,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.white30
                    : Colors.black12,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.white54
                    : Colors.black38,
            width: 2,
          ),
        ),
        filled: true,
        fillColor:
            Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1E293B)
                : const Color(0xFFF1F5F9),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your password';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      keyboardType: TextInputType.name,
      textCapitalization: TextCapitalization.words,
      style: TextStyle(
        color:
            Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: 'Full Name',
        labelStyle: TextStyle(
          color:
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.white70
                  : Colors.black54,
        ),
        prefixIcon: Icon(
          Icons.person_outline,
          color:
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.white54
                  : Colors.black38,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.white30
                    : Colors.black12,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.white30
                    : Colors.black12,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.white54
                    : Colors.black38,
            width: 2,
          ),
        ),
        filled: true,
        fillColor:
            Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1E293B)
                : const Color(0xFFF1F5F9),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your name';
        }
        return null;
      },
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: accentColor.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child:
            _isSubmitting
                ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                : Text(
                  _isLogin ? 'Login' : 'Create Account',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
      ),
    );
  }

  Widget _buildAuthToggle(Color accentColor) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: _isLogin ? null : _toggleAuthMode,
              style: TextButton.styleFrom(
                foregroundColor:
                    _isLogin
                        ? Colors.white
                        : isDarkMode
                        ? Colors.white70
                        : Colors.black54,
                backgroundColor: _isLogin ? accentColor : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                'Login',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: _isLogin ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
          Expanded(
            child: TextButton(
              onPressed: _isLogin ? _toggleAuthMode : null,
              style: TextButton.styleFrom(
                foregroundColor:
                    !_isLogin
                        ? Colors.white
                        : isDarkMode
                        ? Colors.white70
                        : Colors.black54,
                backgroundColor: !_isLogin ? accentColor : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                'Sign Up',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: !_isLogin ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundDecoration(bool isDarkMode) {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF8A4FFF).withOpacity(0.2),
            ),
          ),
        ),
        Positioned(
          bottom: -150,
          left: -50,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFA855F7).withOpacity(0.15),
            ),
          ),
        ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
          child: Container(color: Colors.transparent),
        ),
      ],
    );
  }

  Widget _buildHeader(bool isDarkMode) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFA855F7).withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Image.asset('assets/logo.png', fit: BoxFit.contain),
        ),
        const SizedBox(height: 20),
        Text(
          'HopeCore Hub',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: (isDarkMode ? Colors.black : Colors.grey.shade200)
                .withOpacity(0.3),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            '"Healing Begins When The Silence Ends"',
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: isDarkMode ? Colors.white70 : Colors.black54,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}
