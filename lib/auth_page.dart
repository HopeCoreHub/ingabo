import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'services/auth_service.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage>
    with SingleTickerProviderStateMixin {
  bool _isLogin = true;
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
        if (_isLogin) {
          final success = await authService.login(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );

          if (!success) {
            setState(() {
              _errorMessage = "Invalid email or password. Please try again.";
            });
          } else if (mounted) {
            _showSuccessMessage('Login successful!');
            Navigator.of(context).pop();
          }
        } else {
          // Handle registration with the new enum result
          final result = await authService.register(
            _nameController.text.trim(),
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );

          switch (result) {
            case RegistrationResult.success:
              if (mounted) {
                _showSuccessMessage('Account created successfully!');
                Navigator.of(context).pop();
              }
              break;
            case RegistrationResult.emailAlreadyExists:
              setState(() {
                _errorMessage = "This email is already registered. Please login instead.";
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
          } else if (e.toString().contains('user-not-found') || e.toString().contains('wrong-password')) {
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

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF8A4FFF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
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
      backgroundColor: isDarkMode ? const Color(0xFF111827) : Colors.white,
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
                          const SizedBox(height: 20),
                          _buildHeader(isDarkMode),
                          const SizedBox(height: 40),
                          _buildAuthToggle(accentColor),
                          const SizedBox(height: 30),
                          if (_errorMessage != null) _buildErrorMessage(),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            switchInCurve: Curves.easeIn,
                            switchOutCurve: Curves.easeOut,
                            transitionBuilder: (
                              Widget child,
                              Animation<double> animation,
                            ) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.1),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child:
                                _isLogin
                                    ? _buildLoginForm(accentColor, isDarkMode)
                                    : _buildSignupForm(accentColor, isDarkMode),
                          ),
                          const SizedBox(height: 20),
                          _buildSubmitButton(accentColor),
                          const SizedBox(height: 30),
                          _buildPrivacyNote(isDarkMode),
                          const SizedBox(height: 20),
                          _buildFooter(isDarkMode),
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(isDarkMode ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[300], size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: isDarkMode ? Colors.red[200] : Colors.red[700],
                fontSize: 14,
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

  Widget _buildLoginForm(Color accentColor, bool isDarkMode) {
    return Column(
      key: const ValueKey('login_form'),
      children: [
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            labelText: 'Email Address',
            labelStyle: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
            prefixIcon: Icon(
              Icons.email_outlined,
              color: isDarkMode ? Colors.white54 : Colors.black38,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDarkMode ? Colors.white30 : Colors.black12,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDarkMode ? Colors.white30 : Colors.black12,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accentColor, width: 2),
            ),
            filled: true,
            fillColor:
                isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
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
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            labelText: 'Password',
            labelStyle: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
            prefixIcon: Icon(
              Icons.lock_outline,
              color: isDarkMode ? Colors.white54 : Colors.black38,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: isDarkMode ? Colors.white54 : Colors.black38,
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
                color: isDarkMode ? Colors.white30 : Colors.black12,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDarkMode ? Colors.white30 : Colors.black12,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accentColor, width: 2),
            ),
            filled: true,
            fillColor:
                isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
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
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              // For demo purposes, do nothing
            },
            style: TextButton.styleFrom(
              foregroundColor: accentColor,
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            child: const Text(
              'Forgot Password?',
              style: TextStyle(fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignupForm(Color accentColor, bool isDarkMode) {
    return Column(
      key: const ValueKey('signup_form'),
      children: [
        TextFormField(
          controller: _nameController,
          keyboardType: TextInputType.name,
          textCapitalization: TextCapitalization.words,
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            labelText: 'Full Name',
            labelStyle: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
            prefixIcon: Icon(
              Icons.person_outline,
              color: isDarkMode ? Colors.white54 : Colors.black38,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDarkMode ? Colors.white30 : Colors.black12,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDarkMode ? Colors.white30 : Colors.black12,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accentColor, width: 2),
            ),
            filled: true,
            fillColor:
                isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your name';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            labelText: 'Email Address',
            labelStyle: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
            prefixIcon: Icon(
              Icons.email_outlined,
              color: isDarkMode ? Colors.white54 : Colors.black38,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDarkMode ? Colors.white30 : Colors.black12,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDarkMode ? Colors.white30 : Colors.black12,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accentColor, width: 2),
            ),
            filled: true,
            fillColor:
                isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
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
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            labelText: 'Password',
            labelStyle: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
            prefixIcon: Icon(
              Icons.lock_outline,
              color: isDarkMode ? Colors.white54 : Colors.black38,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: isDarkMode ? Colors.white54 : Colors.black38,
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
                color: isDarkMode ? Colors.white30 : Colors.black12,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDarkMode ? Colors.white30 : Colors.black12,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accentColor, width: 2),
            ),
            filled: true,
            fillColor:
                isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a password';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSubmitButton(Color accentColor) {
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

  Widget _buildPrivacyNote(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.white12 : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.security_outlined,
            color: isDarkMode ? Colors.white54 : Colors.black54,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your privacy is our priority. We protect all your personal information.',
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black54,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isDarkMode) {
    return Text(
      'By continuing, you agree to our Terms of Service and Privacy Policy',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: isDarkMode ? Colors.white54 : Colors.black45,
        fontSize: 12,
      ),
    );
  }
}
