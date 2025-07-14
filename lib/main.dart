import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';
import 'theme_provider.dart';
import 'forum_page.dart';
import 'mahoro_page.dart';
import 'muganga_page.dart';
import 'settings_page.dart';
import 'auth_page.dart';
import 'services/auth_service.dart';
import 'services/forum_service.dart';
import 'services/firebase_service.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  debugPrint('Starting application initialization...');
  
  try {
    // Initialize Firebase directly
    debugPrint('Initializing Firebase directly...');
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('Firebase initialized directly in main.dart');
      
      // Initialize App Check after Firebase is initialized
      await FirebaseAppCheck.instance.activate(
        // Use debug provider for development
        androidProvider: AndroidProvider.debug,
        appleProvider: AppleProvider.debug,
        webProvider: ReCaptchaV3Provider('YOUR_RECAPTCHA_SITE_KEY'),
      );
      debugPrint('Firebase App Check initialized');
    } else {
      debugPrint('Firebase was already initialized');
    }
    
    // Also initialize via service for additional setup
    await FirebaseService.initializeFirebase();
  } catch (e) {
    debugPrint('Error initializing Firebase in main.dart: $e');
    // Continue with app startup even if Firebase fails
  }
  
  // Create auth service instance first
  final authService = AuthService();
  // Create forum service and set auth service
  final forumService = ForumService();
  forumService.setAuthService(authService);
  
  debugPrint('Starting application...');
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider.value(value: authService),
        Provider.value(value: forumService),
        Provider(create: (_) => FirebaseService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HopeCore Hub',
      theme: themeProvider.getTheme(context),
      home: Consumer<AuthService>(
        builder: (context, authService, child) {
          // Show loading indicator while checking auth state
          if (authService.isLoading) {
            return Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          return const MainNavigationWrapper(
            selectedIndex: 0,
            child: HopeCoreHub(),
          );
        }
      ),
    );
  }
}

// New navigation wrapper that contains the bottom navigation bar
class MainNavigationWrapper extends StatefulWidget {
  final Widget child;
  final int selectedIndex;

  const MainNavigationWrapper({
    super.key,
    required this.child,
    required this.selectedIndex,
  });

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> with SingleTickerProviderStateMixin {
  late int _selectedIndex;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final List<GlobalKey<NavigatorState>> _navigatorKeys = List.generate(5, (_) => GlobalKey<NavigatorState>());

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
    _animationController = AnimationController(
      vsync: this,
      duration: ThemeProvider.animationDurationMedium,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: ThemeProvider.animationCurveDefault,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToPage(int index) {
    if (_selectedIndex == index) return;
    
    setState(() {
      _selectedIndex = index;
    });

    Widget page;
    switch (index) {
      case 0:
        page = const HopeCoreHub();
        break;
      case 1:
        page = const ForumPage();
        break;
      case 2:
        page = const MahoroPage();
        break;
      case 3:
        page = const MugangaPage();
        break;
      case 4:
        page = const SettingsPage();
        break;
      default:
        page = const HopeCoreHub();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => 
          MainNavigationWrapper(
            selectedIndex: index,
            child: page,
          ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Define animations for the page being navigated from
          final secondaryCurvedAnimation = CurvedAnimation(
            parent: secondaryAnimation,
            curve: ThemeProvider.pageTransitionCurve,
          );
          
          // Define animations for the page being navigated to
          final primaryCurvedAnimation = CurvedAnimation(
            parent: animation,
            curve: ThemeProvider.pageTransitionCurve,
          );
          
          return Stack(
            children: [
              // Fade and scale out the previous page
              FadeTransition(
                opacity: Tween<double>(begin: 1.0, end: 0.0).animate(secondaryCurvedAnimation),
                child: ScaleTransition(
                  scale: Tween<double>(begin: 1.0, end: 0.95).animate(secondaryCurvedAnimation),
                  child: Container(color: Colors.transparent),
                ),
              ),
              // Fade in and slide in the new page
              FadeTransition(
                opacity: primaryCurvedAnimation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.05, 0),
                    end: Offset.zero,
                  ).animate(primaryCurvedAnimation),
            child: child,
                ),
              ),
            ],
          );
        },
        transitionDuration: ThemeProvider.pageTransitionDuration,
        reverseTransitionDuration: ThemeProvider.pageTransitionDuration,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: widget.child,
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final animation = _animationController.drive(
          CurveTween(curve: const Interval(0.6, 1.0, curve: Curves.easeOutBack)),
        );
        
        // Ensure opacity is between 0.0 and 1.0
        final opacityValue = animation.value.clamp(0.0, 1.0);
        
        return Transform.translate(
          offset: Offset(0, 20 - (20 * animation.value)),
          child: Opacity(
            opacity: opacityValue,
            child: Container(
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Container(
                height: kBottomNavigationBarHeight + 8,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF111827) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(0, Icons.home_outlined, 'Home'),
                    _buildNavItem(1, Icons.chat_bubble_outline, 'Forum'),
                    _buildNavItem(2, Icons.smart_toy_outlined, 'Mahoro'),
                    _buildNavItem(3, Icons.favorite_border, 'Muganga'),
                    _buildNavItem(4, Icons.settings_outlined, 'Settings'),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final selectedColor = const Color(0xFF8A4FFF);
    final unselectedColor = isDarkMode ? Colors.white54 : Colors.black54;
    
    // Calculate animation delay based on index
    final delay = Duration(milliseconds: 50 * index);
    
    return Expanded(
      child: InkWell(
        onTap: () => _navigateToPage(index),
        borderRadius: BorderRadius.circular(16),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: AnimatedOpacity(
          opacity: _animationController.value.clamp(0.0, 1.0),
          duration: ThemeProvider.animationDurationShort,
          curve: ThemeProvider.animationCurveDefault,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: ThemeProvider.animationDurationShort,
                  curve: ThemeProvider.animationCurveSnappy,
                  transform: Matrix4.identity()
                    ..scale(isSelected ? 1.2 : 1.0),
                  transformAlignment: Alignment.center,
                  child: Icon(
                    icon,
                    color: isSelected ? selectedColor : unselectedColor,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 3),
                AnimatedDefaultTextStyle(
                  duration: ThemeProvider.animationDurationShort,
                  style: TextStyle(
                    color: isSelected ? selectedColor : unselectedColor,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 11,
                  ),
                  child: Text(label),
                ),
                const SizedBox(height: 2),
                AnimatedContainer(
                  duration: ThemeProvider.animationDurationShort,
                  width: isSelected ? 20 : 0,
                  height: 2,
                  decoration: BoxDecoration(
                    color: selectedColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
              ),
            ),
          ),
    );
  }
}

class HopeCoreHub extends StatefulWidget {
  const HopeCoreHub({super.key});

  @override
  State<HopeCoreHub> createState() => _HopeCoreHubState();
}

class _HopeCoreHubState extends State<HopeCoreHub> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _navigateToPage(int index) {
    if (index == 0) {
      // Stay on home page
      setState(() {
        _selectedIndex = index;
      });
    } else {
      // No need to navigate - the navigation wrapper handles this now
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  String _getPageName(int index) {
    switch (index) {
      case 1: return 'Forum';
      case 2: return 'Mahoro';
      case 3: return 'Muganga';
      case 4: return 'Settings';
      default: return 'Home';
    }
  }

  Widget _buildUserGreeting() {
    final authService = Provider.of<AuthService>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    if (!authService.isLoggedIn) {
      return const SizedBox.shrink();
    }
    
    final username = authService.username ?? 'User';
    final String firstLetter = username[0].toUpperCase();
    final bool isGuest = username == 'Guest';

    final primaryColor = isDarkMode ? const Color(0xFF8A4FFF) : const Color(0xFFE53935);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode 
            ? [const Color(0xFF1E293B), const Color(0xFF172033)]
            : [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Background decoration (smaller and repositioned)
            Positioned(
              right: -15,
              bottom: -15,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              left: -20,
              top: -20,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withOpacity(0.08),
                ),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [primaryColor, primaryColor.withOpacity(0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        firstLetter,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Welcome, ',
                              style: TextStyle(
                                color: isDarkMode ? Colors.white70 : Colors.black54,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              username,
                              style: TextStyle(
                                color: isDarkMode ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDarkMode 
                              ? primaryColor.withOpacity(0.2) 
                              : primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            isGuest 
                              ? 'Guest mode'
                              : 'How are you today?',
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Settings button
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDarkMode 
                        ? Colors.white.withOpacity(0.1) 
                        : Colors.black.withOpacity(0.05),
                    ),
                    child: IconButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const SettingsPage()),
                        );
                      },
                      icon: Icon(
                        Icons.settings_outlined,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                        size: 18,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF111827) : Colors.white,
      body: SafeArea(
        child: ScrollConfiguration(
          behavior: CustomScrollBehavior(),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            controller: _scrollController,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      FadeSlideTransition(
                        animation: _animationController,
                        begin: const Offset(0, -20),
                        delay: 0.0,
                        child: _buildHeader(),
                      ),
                      const SizedBox(height: 14),
                      FadeSlideTransition(
                        animation: _animationController,
                        begin: const Offset(0, -15),
                        delay: 0.05,
                        child: _buildUserGreeting(),
                      ),
                      const SizedBox(height: 14),
                      FadeSlideTransition(
                        animation: _animationController,
                        begin: const Offset(0, -10),
                        delay: 0.1,
                        child: _buildEmergencyButton(),
                      ),
                      const SizedBox(height: 16),
                      FadeSlideTransition(
                        animation: _animationController,
                        begin: const Offset(0, 0),
                        delay: 0.2,
                        child: _buildQuickAccessSection(),
                      ),
                      const SizedBox(height: 16),
                      FadeSlideTransition(
                        animation: _animationController,
                        begin: const Offset(0, 10),
                        delay: 0.3,
                        child: _buildFeelingsSection(),
                      ),
                      const SizedBox(height: 16),
                      FadeSlideTransition(
                        animation: _animationController,
                        begin: const Offset(0, 10),
                        delay: 0.4,
                        child: _buildResourcesSection(),
                      ),
                      const SizedBox(height: 16),
                      FadeSlideTransition(
                        animation: _animationController,
                        begin: const Offset(0, 10),
                        delay: 0.5,
                        child: _buildDailyAffirmationSection(),
                      ),
                      const SizedBox(height: 16),
                      FadeSlideTransition(
                        animation: _animationController,
                        begin: const Offset(0, 10),
                        delay: 0.6,
                        child: _buildEmergencyContactsSection(),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode 
            ? [const Color(0xFF111827), const Color(0xFF1E293B)]
            : [const Color(0xFFF9FAFB), const Color(0xFFE5E7EB)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Profile button
              Hero(
                tag: 'profile_button',
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const MainNavigationWrapper(
                          selectedIndex: 0,
                          child: AuthPage(),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDarkMode ? const Color(0xFFE5E7EB) : const Color(0xFF1E293B),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 10,
                          spreadRadius: 0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.person_outline,
                      color: isDarkMode ? const Color(0xFF111827) : Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              
              // Theme toggle
              Hero(
                tag: 'theme_toggle',
                child: GestureDetector(
                  onTap: () {
                    themeProvider.toggleDarkMode(!themeProvider.isDarkMode);
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 10,
                          spreadRadius: 0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      isDarkMode ? Icons.wb_sunny_outlined : Icons.brightness_2_outlined,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Logo and title
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Hero(
                  tag: 'app_logo',
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isDarkMode ? const Color(0xFF8A4FFF) : const Color(0xFFE53935))
                            .withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return LinearGradient(
                          colors: isDarkMode 
                            ? [const Color(0xFF8A4FFF), const Color(0xFF6D28D9)]
                            : [const Color(0xFFE53935), const Color(0xFFD32F2F)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds);
                      },
                      child: Text(
                        'HopeCore Hub',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDarkMode ? const Color(0xFF0F172A).withOpacity(0.7) : Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Your safe space for healing',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 0.3,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyButton() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(0.5, 0.8, curve: Curves.easeInOut),
          ),
        );
        
        return Transform.scale(
          scale: pulseAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE53935), Color(0xFFC62828)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE53935).withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 1,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                splashColor: Colors.white.withOpacity(0.1),
                highlightColor: Colors.transparent,
                onTap: () {
                  _playButtonPressAnimation();
                  HapticFeedback.mediumImpact();
                  
                  // Show quick action dialog for emergency call
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                        title: Text(
                          'Emergency Call',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        content: Text(
                          'Would you like to call emergency services now?',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: isDarkMode ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _makePhoneCall('112'); // Rwanda emergency number
                            },
                            child: Text(
                              'Call Now',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.phone, 
                          color: Colors.white, 
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'SOS - Emergency Help',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Get immediate support',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward, 
                          color: Colors.white, 
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickAccessSection() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ShaderMask(
              shaderCallback: (Rect bounds) {
                return LinearGradient(
                  colors: isDarkMode 
                    ? [const Color(0xFF8A4FFF), const Color(0xFF6D28D9)]
                    : [const Color(0xFFE53935), const Color(0xFFD32F2F)],
                ).createShader(bounds);
              },
              child: Icon(
                Icons.bolt,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Quick Access',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.25, // Make cards less tall
          children: [
            _buildAnimatedQuickAccessItem(
              color: const Color(0xFF6366F1),
              icon: Icons.chat_bubble_outline,
              title: 'Forum',
              subtitle: 'Connect with community',
              delay: 0.1,
            ),
            _buildAnimatedQuickAccessItem(
              color: const Color(0xFF3B82F6),
              icon: Icons.smart_toy_outlined,
              title: 'Mahoro',
              subtitle: 'AI Support Companion',
              delay: 0.2,
            ),
            _buildAnimatedQuickAccessItem(
              color: const Color(0xFF10B981),
              icon: Icons.favorite_outline,
              title: 'Muganga',
              subtitle: 'Professional Support',
              delay: 0.3,
            ),
            _buildAnimatedQuickAccessItem(
              color: const Color(0xFF6B7280),
              icon: Icons.settings_outlined,
              title: 'Settings',
              subtitle: 'Customize your experience',
              delay: 0.4,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnimatedQuickAccessItem({
    required Color color,
    required IconData icon,
    required String title,
    required String subtitle,
    required double delay,
  }) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final delayedAnimation = _animationController.drive(
          CurveTween(curve: Interval(delay, 1.0, curve: Curves.easeOutBack)),
        );
        // Clamp the opacity value to ensure it stays between 0.0 and 1.0
        final opacityValue = delayedAnimation.value.clamp(0.0, 1.0);
        
        return Transform.scale(
          scale: 0.85 + (0.15 * delayedAnimation.value),
          child: Opacity(
            opacity: opacityValue,
            child: _buildQuickAccessItem(
              color: color,
              icon: icon,
              title: title,
              subtitle: subtitle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickAccessItem({
    required Color color,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return GestureDetector(
      onTap: () {
        _playItemPressAnimation(title);
        int index = 0;
        Widget page;
        
        if (title == 'Forum') {
          page = const ForumPage();
          index = 1;
        } else if (title == 'Mahoro') {
          page = const MahoroPage();
          index = 2;
        } else if (title == 'Muganga') {
          page = const MugangaPage();
          index = 3;
        } else if (title == 'Settings') {
          page = const SettingsPage();
          index = 4;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$title page coming soon'),
              duration: const Duration(seconds: 1),
            ),
          );
          return;
        }
        
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => 
              MainNavigationWrapper(
                selectedIndex: index,
                child: page,
              ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color,
              Color.lerp(color, isDarkMode ? Colors.black : Colors.white, 0.3)!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.25),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 22,
              ),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeelingsSection() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final primaryColor = isDarkMode ? const Color(0xFF8A4FFF) : const Color(0xFFE53935);
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode 
            ? [const Color(0xFF2A3B53), const Color(0xFF1E293B)]
            : [const Color(0xFFFFEFEF), const Color(0xFFFAF0F0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDarkMode 
                      ? [const Color(0xFF8A4FFF), const Color(0xFF6D28D9)]
                      : [const Color(0xFFE53935), const Color(0xFFD32F2F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'How are you feeling today?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildEmotionButton('😀', 'Great', 0.1, isDarkMode),
                _buildEmotionButton('😊', 'Good', 0.2, isDarkMode),
                _buildEmotionButton('😐', 'Okay', 0.3, isDarkMode),
                _buildEmotionButton('😔', 'Sad', 0.4, isDarkMode),
                _buildEmotionButton('😣', 'Bad', 0.5, isDarkMode),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionButton(String emotion, String label, double delay, bool isDarkMode) {
    final primaryColor = isDarkMode ? const Color(0xFF8A4FFF) : const Color(0xFFE53935);
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final delayedAnimation = _animationController.drive(
          CurveTween(curve: Interval(0.4 + delay, 1.0, curve: Curves.easeOutBack)),
        );
        
        // Ensure opacity is between 0.0 and 1.0
        final opacityValue = delayedAnimation.value.clamp(0.0, 1.0);
        
        return Transform.scale(
          scale: 0.7 + (0.3 * delayedAnimation.value),
          child: Opacity(
            opacity: opacityValue,
            child: GestureDetector(
              onTap: () => _playEmotionSelectAnimation(emotion),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                          isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: isDarkMode 
                            ? Colors.black.withOpacity(0.15) 
                            : primaryColor.withOpacity(0.1),
                          blurRadius: 8,
                          spreadRadius: 0,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        emotion,
                        style: const TextStyle(
                          fontSize: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildResourcesSection() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ShaderMask(
              shaderCallback: (Rect bounds) {
                return LinearGradient(
                  colors: isDarkMode 
                    ? [const Color(0xFF8A4FFF), const Color(0xFF6D28D9)]
                    : [const Color(0xFFE53935), const Color(0xFFD32F2F)],
                ).createShader(bounds);
              },
              child: Icon(
                Icons.category,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Resources',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildAnimatedResourceItem(
          color: Colors.red,
          icon: Icons.favorite,
          title: 'Self-Care Tips',
          subtitle: 'Daily wellness practices',
          delay: 0.1,
        ),
        const SizedBox(height: 10),
        _buildAnimatedResourceItem(
          color: Colors.blue,
          icon: Icons.shield_outlined,
          title: 'Safety Planning',
          subtitle: 'Personal safety resources',
          delay: 0.2,
        ),
        const SizedBox(height: 10),
        _buildAnimatedResourceItem(
          color: Colors.green,
          icon: Icons.call,
          title: 'Crisis Support',
          subtitle: '24/7 helpline numbers',
          delay: 0.3,
        ),
        const SizedBox(height: 10),
        _buildAnimatedResourceItem(
          color: Colors.purple,
          icon: Icons.menu_book,
          title: 'Educational Content',
          subtitle: 'Learn about healing',
          delay: 0.4,
        ),
      ],
    );
  }

  Widget _buildAnimatedResourceItem({
    required Color color,
    required IconData icon,
    required String title,
    required String subtitle,
    required double delay,
  }) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final delayedAnimation = _animationController.drive(
          CurveTween(curve: Interval(0.3 + delay, 1.0, curve: Curves.easeOutBack)),
        );
        
        // Ensure opacity is between 0.0 and 1.0
        final opacityValue = delayedAnimation.value.clamp(0.0, 1.0);
        
        return Transform.translate(
          offset: Offset(20 - (20 * delayedAnimation.value), 0),
          child: Opacity(
            opacity: opacityValue,
            child: _buildResourceItem(
              color: color,
              icon: icon,
              title: title,
              subtitle: subtitle,
            ),
          ),
        );
      }
    );
  }

  Widget _buildResourceItem({
    required Color color,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return GestureDetector(
      onTap: () => _playItemPressAnimation(title),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              isDarkMode ? const Color(0xFF1E293B) : Colors.white,
              isDarkMode ? const Color(0xFF172033) : const Color(0xFFF9FAFB),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: color.withOpacity(0.08),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_ios,
                color: color,
                size: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyAffirmationSection() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final primaryColor = isDarkMode ? const Color(0xFF8A4FFF) : const Color(0xFFE53935);
    
    return Container(
      padding: const EdgeInsets.all(0),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: isDarkMode 
            ? [const Color(0xFF2A205D), const Color(0xFF362C72)]
            : [const Color(0xFFFFE1E0), const Color(0xFFFFF0F0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
              ? const Color(0xFF2A205D).withOpacity(0.4) 
              : primaryColor.withOpacity(0.15),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            // Background decoration
            Positioned(
              right: -15,
              top: -15,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              left: -20,
              bottom: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.format_quote,
                      color: isDarkMode ? Colors.white : primaryColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Daily Affirmation',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(isDarkMode ? 0.1 : 0.8),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 6,
                                spreadRadius: 0,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '"You are stronger than you know, braver than you feel, and more loved than you imagine."',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              fontStyle: FontStyle.italic,
                              color: isDarkMode ? Colors.white : Colors.black87,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.start,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyContactsSection() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF9B1C1C), const Color(0xFF771D1D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9B1C1C).withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            // Background decoration elements (smaller and repositioned)
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            Positioned(
              left: -15,
              bottom: -35,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.phone_enabled,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Emergency Contacts',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        _buildEmergencyContact(
                          'Isange One Stop Center:', 
                          '3029', 
                          Icons.local_hospital,
                        ),
                        const SizedBox(height: 8),
                        _buildDivider(),
                        const SizedBox(height: 8),
                        _buildEmergencyContact(
                          'Rwanda National Police:', 
                          '3512',
                          Icons.local_police,
                        ),
                        const SizedBox(height: 8),
                        _buildDivider(),
                        const SizedBox(height: 8),
                        _buildEmergencyContact(
                          'HopeCore Team:', 
                          '+250780332779',
                          Icons.support_agent,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Help is available 24/7',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      width: double.infinity,
      color: Colors.white.withOpacity(0.1),
    );
  }
  
  Widget _buildEmergencyContact(String label, String number, IconData icon) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 16,
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 1),
            Text(
              number,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const Spacer(),
        InkWell(
          onTap: () => _makePhoneCall(number),
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.call,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
      ],
    );
  }
  
  void _playButtonPressAnimation() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        final themeProvider = Provider.of<ThemeProvider>(context);
        final isDarkMode = themeProvider.isDarkMode;
        
        return Dialog(
          backgroundColor: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      color: isDarkMode ? Colors.white60 : Colors.black54,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite,
                      color: const Color(0xFF8A4FFF),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'You Are Not Alone',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF8A4FFF),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Everything is going to be okay. 💜',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'If you\'re in immediate danger, we\'re here to help connect you with the right support. You are brave for reaching out.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'How would you like to get help?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Close the initial dialog
                      Navigator.of(context).pop();
                      
                      // Show emergency contact options
                      showDialog(
                        context: context,
                        barrierDismissible: true,
                        builder: (BuildContext dialogContext) {
                          return Dialog(
                            backgroundColor: const Color(0xFF0A1929),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        onPressed: () => Navigator.of(dialogContext).pop(),
                                        icon: const Icon(Icons.close),
                                        color: Colors.white60,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.phone,
                                        color: Colors.red,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Choose Emergency Contact',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Select who you\'d like to call for immediate assistance:',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  
                                  // Isange One Stop Center
                                  _buildContactCard(
                                    title: 'Isange One Stop Center',
                                    number: '3029',
                                    description: 'Gender-based violence support',
                                    dialogContext: dialogContext,
                                  ),
                                  
                                  const SizedBox(height: 12),
                                  
                                  // Rwanda Investigation Bureau (RIB)
                                  _buildContactCard(
                                    title: 'Rwanda Investigation Bureau (RIB)',
                                    number: '3512',
                                    description: 'Criminal investigations & safety',
                                    dialogContext: dialogContext,
                                  ),
                                  
                                  const SizedBox(height: 12),
                                  
                                  // HopeCore Hub Team
                                  _buildContactCard(
                                    title: 'HopeCore Hub Team',
                                    number: '0780332779',
                                    description: 'We\'ll help contact authorities',
                                    dialogContext: dialogContext,
                                  ),
                                  
                                  const SizedBox(height: 24),
                                  
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(dialogContext).pop();
                                      _playButtonPressAnimation();
                                    },
                                    child: Text(
                                      'Back',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.phone, color: Colors.white),
                    label: const Text(
                      'Make a Phone Call',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Close the current dialog first
                      Navigator.of(context).pop();
                      // Show the text messaging dialog
                      _sendTextMessage();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF8A4FFF),
                      side: const BorderSide(color: Color(0xFF8A4FFF)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text(
                      'Send a Text Message',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white60 : Colors.black54,
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
  
  void _playEmotionSelectAnimation(String emotion) {
    HapticFeedback.lightImpact();
    
    // Show emotion selection dialog instead of just a snackbar
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    final accentColor = isDarkMode ? const Color(0xFF8A4FFF) : const Color(0xFFE53935);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      color: isDarkMode ? Colors.white60 : Colors.black54,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                Text(
                  emotion,
                  style: const TextStyle(
                    fontSize: 48,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'How can we support you today?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  _getEmotionMessage(emotion),
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      
                      // Navigate to Mahoro for support
                      Navigator.of(context).pushReplacement(
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => 
                            MainNavigationWrapper(
                              selectedIndex: 2,
                              child: const MahoroPage(),
                            ),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          },
                          transitionDuration: const Duration(milliseconds: 300),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Talk to Mahoro',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
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
  
  String _getEmotionMessage(String emotion) {
    switch (emotion) {
      case '😀':
        return "It's great to see you're feeling good! Would you like to share your positive experiences or learn ways to maintain this mood?";
      case '😐':
        return "Sometimes we all feel a bit neutral. Would you like to talk about what's on your mind or explore ways to boost your mood?";
      case '😔':
        return "I'm sorry you're feeling down. Remember that it's okay to not be okay, and talking about it can help. Would you like some support?";
      case '😣':
        return "I can see you're having a difficult time. Please remember you're not alone, and there are resources available to help you through this.";
      default:
        return "Thank you for sharing how you're feeling. Would you like to talk more about it?";
    }
  }
  
  void _playItemPressAnimation(String resourceTitle) {
    HapticFeedback.lightImpact();
    
    // Navigate to appropriate page based on the title
    if (resourceTitle == 'Forum') {
      _navigateToPage(1);
    } else if (resourceTitle == 'Mahoro') {
      _navigateToPage(2);
    } else if (resourceTitle == 'Muganga') {
      _navigateToPage(3);
    } else if (resourceTitle == 'Settings') {
      _navigateToPage(4);
    } else {
      // Show resource dialog for other items
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      final isDarkMode = themeProvider.isDarkMode;
      
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          resourceTitle,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        color: isDarkMode ? Colors.white60 : Colors.black54,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildResourceContent(resourceTitle, isDarkMode),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getResourceColor(resourceTitle),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Got it',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
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
  }
  
  Widget _buildResourceContent(String resourceTitle, bool isDarkMode) {
    // Customize content based on resource title
    switch (resourceTitle) {
      case 'Self-Care Tips':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResourceListItem(text: 'Practice deep breathing for 5 minutes', isDarkMode: isDarkMode),
            _buildResourceListItem(text: 'Stay hydrated throughout the day', isDarkMode: isDarkMode),
            _buildResourceListItem(text: 'Get at least 7-8 hours of sleep', isDarkMode: isDarkMode),
            _buildResourceListItem(text: 'Take short breaks during work', isDarkMode: isDarkMode),
            _buildResourceListItem(text: 'Connect with supportive friends and family', isDarkMode: isDarkMode),
          ],
        );
      case 'Safety Planning':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResourceListItem(text: 'Identify safe locations you can go to', isDarkMode: isDarkMode),
            _buildResourceListItem(text: 'Save emergency contact numbers', isDarkMode: isDarkMode),
            _buildResourceListItem(text: 'Keep important documents accessible', isDarkMode: isDarkMode),
            _buildResourceListItem(text: 'Create a code word with trusted friends', isDarkMode: isDarkMode),
            _buildResourceListItem(text: 'Know the locations of local resources', isDarkMode: isDarkMode),
          ],
        );
      case 'Crisis Support':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResourceListItem(text: 'Isange One Stop Center: 3029', isDarkMode: isDarkMode),
            _buildResourceListItem(text: 'Rwanda National Police: 112', isDarkMode: isDarkMode),
            _buildResourceListItem(text: 'RIB Hotline: 3512', isDarkMode: isDarkMode),
            _buildResourceListItem(text: 'Mental Health Helpline: 114', isDarkMode: isDarkMode),
            _buildResourceListItem(text: 'HopeCore Team: +250780332779', isDarkMode: isDarkMode),
          ],
        );
      case 'Educational Content':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResourceListItem(text: 'Understanding trauma responses', isDarkMode: isDarkMode),
            _buildResourceListItem(text: 'Recognizing healthy relationships', isDarkMode: isDarkMode),
            _buildResourceListItem(text: 'Building resilience skills', isDarkMode: isDarkMode),
            _buildResourceListItem(text: 'Managing anxiety and stress', isDarkMode: isDarkMode),
            _buildResourceListItem(text: 'Supporting others in need', isDarkMode: isDarkMode),
          ],
        );
      default:
        return Text(
          'Content coming soon...',
          style: TextStyle(
            fontSize: 16,
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
        );
    }
  }
  
  Widget _buildResourceListItem({required String text, required bool isDarkMode}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            color: const Color(0xFF8A4FFF),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getResourceColor(String resourceTitle) {
    switch (resourceTitle) {
      case 'Self-Care Tips':
        return Colors.red;
      case 'Safety Planning':
        return Colors.blue;
      case 'Crisis Support':
        return Colors.green;
      case 'Educational Content':
        return Colors.purple;
      default:
        return const Color(0xFF8A4FFF);
    }
  }
  
  // Helper method to build contact cards
  Widget _buildContactCard({
    required String title,
    required String number,
    required String description,
    required BuildContext dialogContext,
  }) {
    return InkWell(
      onTap: () {
        Navigator.of(dialogContext).pop();
        _makePhoneCall(number);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              number,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              description,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // New method to make phone calls
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch phone call to $phoneNumber'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error making phone call: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error making phone call: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
  
  // Method to handle sending text messages
  void _sendTextMessage() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: isDarkMode ? const Color(0xFF0A1929) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      color: isDarkMode ? Colors.white60 : Colors.black54,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.message,
                      color: const Color(0xFF8A4FFF),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Send Emergency Message',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF8A4FFF),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Select who you\'d like to message for support:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Message templates
                _buildMessageOption(
                  title: 'Isange One Stop Center',
                  number: '3029',
                  message: 'Hello, I need help regarding a safety concern.',
                  isDarkMode: isDarkMode,
                ),
                
                const SizedBox(height: 12),
                
                _buildMessageOption(
                  title: 'HopeCore Support',
                  number: '0780332779',
                  message: 'Hello, I\'m reaching out because I need support.',
                  isDarkMode: isDarkMode,
                ),
                
                const SizedBox(height: 12),
                
                _buildMessageOption(
                  title: 'Trusted Contact',
                  number: 'Add your contact',
                  message: 'Hi, I need to talk. Could you please call me when you have a moment?',
                  isDarkMode: isDarkMode,
                  isCustom: true,
                ),
                
                const SizedBox(height: 16),
                
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _playButtonPressAnimation();
                  },
                  child: Text(
                    'Back to Options',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
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
  
  Widget _buildMessageOption({
    required String title,
    required String number,
    required String message,
    required bool isDarkMode,
    bool isCustom = false,
  }) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        
        if (isCustom) {
          // Show dialog to add a custom contact
          _showAddContactDialog();
        } else {
          // Send SMS
          _sendSms(number, message);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  number,
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF8A4FFF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.white70 : Colors.black54,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  isCustom ? Icons.add_circle_outline : Icons.send,
                  size: 18,
                  color: const Color(0xFF8A4FFF),
                ),
                const SizedBox(width: 6),
                Text(
                  isCustom ? 'Add Contact' : 'Send Message',
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF8A4FFF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _sendSms(String phoneNumber, String message) async {
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: phoneNumber,
      queryParameters: {'body': message},
    );
    
    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch SMS to $phoneNumber'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error sending SMS: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending SMS: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
  
  void _showAddContactDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    final TextEditingController nameController = TextEditingController();
    final TextEditingController numberController = TextEditingController();
    final TextEditingController messageController = TextEditingController(
      text: 'Hi, I need to talk. Could you please call me when you have a moment?'
    );
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add Trusted Contact',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    color: isDarkMode ? Colors.white60 : Colors.black54,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Contact Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: numberController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                decoration: InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        final number = numberController.text.trim();
                        if (number.isNotEmpty) {
                          _makePhoneCall(number);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a valid phone number'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.call, color: Colors.white),
                      label: const Text(
                        'Call',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        final number = numberController.text.trim();
                        final message = messageController.text.trim();
                        
                        if (number.isNotEmpty) {
                          _sendSms(number, message);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a valid phone number'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.message, color: Colors.white),
                      label: const Text(
                        'Message',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8A4FFF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom scroll behavior for smooth scrolling
class CustomScrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }
}

// Fade and slide transition widget
class FadeSlideTransition extends StatelessWidget {
  final Animation<double> animation;
  final Offset begin;
  final double delay;
  final Widget child;

  const FadeSlideTransition({
    super.key,
    required this.animation,
    required this.begin,
    required this.delay,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Create delayed animation
    final delayedAnimation = animation.drive(
      CurveTween(curve: Interval(delay, 1.0, curve: Curves.easeOut)),
    );

    return AnimatedBuilder(
      animation: delayedAnimation,
      builder: (context, child) {
        // Ensure opacity is between 0.0 and 1.0
        final opacityValue = delayedAnimation.value.clamp(0.0, 1.0);
        
        return Opacity(
          opacity: opacityValue,
          child: Transform.translate(
            offset: Offset(
              begin.dx * (1 - delayedAnimation.value), 
              begin.dy * (1 - delayedAnimation.value),
            ),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
