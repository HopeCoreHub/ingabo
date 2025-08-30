import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:animated_emoji/animated_emoji.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'firebase_options.dart';
import 'theme_provider.dart';
import 'theme_style_provider.dart';
import 'language_provider.dart';
import 'accessibility_provider.dart';
import 'data_performance_provider.dart';
import 'notification_provider.dart';
import 'forum_page.dart';
import 'mahoro_page.dart';
import 'muganga_page.dart';
import 'settings_page.dart';
import 'auth_page.dart';
import 'services/auth_service.dart';
import 'services/forum_service.dart';
import 'services/firebase_service.dart';
import 'services/firebase_realtime_service.dart';
import 'services/speech_service.dart';
import 'services/offline_service.dart';
import 'localization/app_localizations.dart';
import 'localization/localization_wrapper.dart';
import 'localization/localized_text.dart';
import 'localization/base_screen.dart';
import 'package:firebase_database/firebase_database.dart';
import 'admin_setup_page.dart';
import 'dashboard_page.dart';
import 'utils/accessibility_utils.dart';
import 'widgets/ai_content_policy_notice.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  debugPrint('Starting application initialization...');
  
  try {
    // Enhanced Firebase initialization with web-specific handling
    debugPrint('Initializing Firebase...');
    
    if (kIsWeb) {
      // Web-specific Firebase initialization with retry logic
      debugPrint('Initializing Firebase for web platform...');
      
      // Add delay to ensure Firebase JS SDK is fully loaded
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Retry logic for Firebase initialization
      bool firebaseInitialized = false;
      int retryCount = 0;
      const maxRetries = 5;
      
      while (!firebaseInitialized && retryCount < maxRetries) {
        try {
          if (Firebase.apps.isEmpty) {
            await Firebase.initializeApp(
              options: DefaultFirebaseOptions.currentPlatform,
            );
            firebaseInitialized = true;
            debugPrint('Firebase initialized successfully for web (attempt ${retryCount + 1})');
          } else {
            firebaseInitialized = true;
            debugPrint('Firebase was already initialized for web');
          }
        } catch (e) {
          retryCount++;
          debugPrint('Firebase initialization attempt $retryCount failed: $e');
          if (retryCount < maxRetries) {
            debugPrint('Retrying Firebase initialization in ${retryCount * 200}ms...');
            await Future.delayed(Duration(milliseconds: retryCount * 200));
          }
        }
      }
      
      if (!firebaseInitialized) {
        debugPrint('Warning: Failed to initialize Firebase after $maxRetries attempts');
      }
    } else {
      // Mobile/Desktop platform initialization
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        debugPrint('Firebase initialized for mobile/desktop platform');
      } else {
        debugPrint('Firebase was already initialized for mobile/desktop');
      }
    }
    
    debugPrint('Firebase initialized with database URL from configuration');
    
    // Initialize Firebase services with error handling
    try {
      await FirebaseService.initializeFirebase();
      debugPrint('Firebase Service initialized successfully');
    } catch (e) {
      debugPrint('Warning: Firebase Service initialization failed: $e');
      // Continue without Firebase Service
    }
    
    // Initialize Realtime Database for forum posts
    try {
      final realtimeDB = FirebaseRealtimeService();
      debugPrint('Firebase Realtime Database initialized for forum posts');
    } catch (e) {
      debugPrint('Warning: Firebase Realtime Database initialization failed: $e');
      // Continue without Realtime Database
    }
    
  } catch (e) {
    debugPrint('Error initializing Firebase: $e');
    if (kIsWeb) {
      debugPrint('Web Firebase initialization failed. The app will continue with limited functionality.');
    }
    // Continue with app startup even if Firebase fails completely
  }
  
  // Create service instances with error handling
  final authService = AuthService();
  final forumService = ForumService();
  forumService.setAuthService(authService);
  
  // Initialize speech service with error handling
  final speechService = SpeechService();
  try {
    await speechService.initialize();
    debugPrint('Speech service initialized successfully');
  } catch (e) {
    debugPrint('Warning: Speech service initialization failed: $e');
  }
  
  final offlineService = OfflineService();
  
  debugPrint('Starting application...');
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => AccessibilityProvider()),
        ChangeNotifierProvider(create: (_) => DataPerformanceProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider.value(value: authService),
        Provider.value(value: forumService),
        Provider(create: (_) => FirebaseService()),
        Provider.value(value: speechService),
        Provider.value(value: offlineService),
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
    final languageProvider = Provider.of<LanguageProvider>(context);
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
    
    // Create theme style provider
    final themeStyleProvider = ThemeStyleProvider(
      themeProvider: themeProvider,
      accessibilityProvider: accessibilityProvider,
    );
    
    return LocalizationWrapper(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'HopeCore Hub',
        theme: themeStyleProvider.getThemeWithAccessibility(context),
        routes: {
          '/admin_setup': (context) => const AdminSetupPage(),
        },
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
            
            // Force the app to respond to auth state changes
            // If logged in, show main app, otherwise show auth page or guest mode
            if (authService.isLoggedIn) {
              debugPrint('User is logged in as ${authService.username}');
              return const MainNavigationWrapper(
                selectedIndex: 0,
                child: HopeCoreHub(),
              );
            } else {
              // Show guest mode - we could also redirect to auth page here
              debugPrint('User is in guest mode');
              return const MainNavigationWrapper(
                selectedIndex: 0,
                child: HopeCoreHub(),
              );
            }
          }
        ),
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
        page = const DashboardPage();
        break;
      case 1:
        page = const HopeCoreHub();
        break;
      case 2:
        page = const ForumPage();
        break;
      case 3:
        page = const MahoroPage();
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
                  color: AccessibilityUtils.getAccessibleSurfaceColor(context),
                  borderRadius: BorderRadius.circular(16),
                  border: AccessibilityUtils.isHighContrastEnabled(context) 
                      ? Border.all(
                          color: AccessibilityUtils.getAccessibleBorderColor(context),
                          width: 3.0, // Thicker border for navigation
                        )
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(0, Icons.dashboard_outlined, 'dashboard'),
                    _buildNavItem(1, Icons.home_outlined, 'home'),
                    _buildNavItem(2, Icons.chat_bubble_outline, 'forum'),
                    _buildNavItem(3, Icons.smart_toy_outlined, 'mahoro'),
                    _buildNavItem(4, Icons.settings_outlined, 'settings'),
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
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final highContrastMode = accessibilityProvider.highContrastMode;
    final selectedColor = const Color(0xFF8A4FFF);
    final unselectedColor = isDarkMode ? Colors.white54 : Colors.black54;
    
    // High contrast colors
    final highContrastSelectedColor = isDarkMode ? Colors.white : Colors.black;
    final highContrastUnselectedColor = isDarkMode ? Colors.white70 : Colors.black54;
    
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
                    color: highContrastMode
                        ? (isSelected ? highContrastSelectedColor : highContrastUnselectedColor)
                        : (isSelected ? selectedColor : unselectedColor),
                    size: 22,
                  ),
                ),
                const SizedBox(height: 3),
                AnimatedDefaultTextStyle(
                  duration: ThemeProvider.animationDurationShort,
                  style: TextStyle(
                    color: highContrastMode
                        ? (isSelected ? highContrastSelectedColor : highContrastUnselectedColor)
                        : (isSelected ? selectedColor : unselectedColor),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 11,
                  ),
                  child: LocalizedText(label),
                ),
                const SizedBox(height: 2),
                AnimatedContainer(
                  duration: ThemeProvider.animationDurationShort,
                  width: isSelected ? 20 : 0,
                  height: 2,
                  decoration: BoxDecoration(
                    color: highContrastMode
                        ? highContrastSelectedColor
                        : selectedColor,
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

class HopeCoreHub extends BaseScreen {
  const HopeCoreHub({super.key});

  @override
  State<HopeCoreHub> createState() => _HopeCoreHubState();
}

class _HopeCoreHubState extends BaseScreenState<HopeCoreHub> with SingleTickerProviderStateMixin {
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
    
    // Show content policy notice on first launch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AiContentPolicyNotice.showIfNeeded(context);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _navigateToPage(int index) {
    if (index == 1) {
      // Stay on home page
      setState(() {
        _selectedIndex = index;
      });
    } else {
      // Navigate to the appropriate page
      Widget page;
      switch (index) {
        case 0:
          page = const DashboardPage();
          break;
        case 2:
          page = const ForumPage();
          break;
        case 3:
          page = const MahoroPage();
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
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
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
    final authService = Provider.of<AuthService>(context, listen: true);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final highContrastMode = accessibilityProvider.highContrastMode;
    
    // Ensure we're checking the actual auth state
    debugPrint('Auth state in greeting: isLoggedIn=${authService.isLoggedIn}, username=${authService.username}');
    
    // Attempt to reload auth state when user is in guest mode but shouldn't be
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!authService.isLoading) {
        authService.reloadAuthState();
      }
    });
    
    final username = authService.username ?? 'Guest';
    final String firstLetter = username[0].toUpperCase();
    final bool isGuest = username == 'Guest' || !authService.isLoggedIn;

    final primaryColor = isDarkMode ? const Color(0xFF8A4FFF) : const Color(0xFFE53935);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        gradient: highContrastMode 
            ? null 
            : LinearGradient(
                colors: isDarkMode 
                  ? [const Color(0xFF1E293B), const Color(0xFF172033)]
                  : [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        color: highContrastMode 
            ? (isDarkMode ? Colors.black : Colors.white)
            : null,
        borderRadius: BorderRadius.circular(16),
        border: highContrastMode
            ? Border.all(color: isDarkMode ? Colors.white : Colors.black, width: 2.0)
            : null,
        boxShadow: highContrastMode 
            ? null 
            : [
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
                            LocalizedText(
                              'welcomeBack',
                              style: TextStyle(
                                color: highContrastMode 
                                    ? (isDarkMode ? Colors.white70 : Colors.black54)
                                    : (isDarkMode ? Colors.white70 : Colors.black54),
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              username,
                              style: TextStyle(
                                color: highContrastMode 
                                    ? (isDarkMode ? Colors.white : Colors.black)
                                    : (isDarkMode ? Colors.white : Colors.black87),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            if (isGuest) 
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => _showLoginPrompt(),
                                    child: Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: Colors.red.withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        'Guest Mode',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      final authService = Provider.of<AuthService>(context, listen: false);
                                      authService.reloadAuthState();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Refreshing login status...'),
                                          duration: Duration(seconds: 1),
                                          backgroundColor: primaryColor,
                                        )
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: Icon(
                                        Icons.refresh,
                                        size: 14,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: highContrastMode 
                                ? (isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1))
                                : (isDarkMode 
                                    ? primaryColor.withOpacity(0.2) 
                                    : primaryColor.withOpacity(0.1)),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            isGuest 
                              ? 'Log in to access all features'
                              : 'How are you today?',
                            style: TextStyle(
                              color: highContrastMode 
                                  ? (isDarkMode ? Colors.white : Colors.black)
                                  : primaryColor,
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
                      color: highContrastMode 
                          ? (isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1))
                          : (isDarkMode 
                              ? Colors.white.withOpacity(0.1) 
                              : Colors.black.withOpacity(0.05)),
                    ),
                    child: IconButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const SettingsPage()),
                        );
                      },
                      icon: Icon(
                        Icons.settings_outlined,
                        color: highContrastMode 
                            ? (isDarkMode ? Colors.white : Colors.black)
                            : (isDarkMode ? Colors.white70 : Colors.black54),
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
  
  // Show login prompt dialog when user clicks on Guest Mode indicator
  void _showLoginPrompt() {
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
                    Icons.person_outline,
                    color: const Color(0xFF8A4FFF),
                    size: 30,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Guest Mode',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'You\'re currently using the app as a guest. Sign in or create an account to access all features and save your progress.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const AuthPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8A4FFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Login / Register',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Continue as Guest',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white60 : Colors.black54,
                      fontSize: 14,
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

  @override
  Widget buildScreen(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final highContrastMode = accessibilityProvider.highContrastMode;
    
    return Scaffold(
      backgroundColor: highContrastMode 
          ? (isDarkMode ? Colors.black : Colors.white)
          : (isDarkMode ? const Color(0xFF111827) : Colors.white),
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
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final highContrastMode = accessibilityProvider.highContrastMode;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: highContrastMode
            ? null // No gradients in high contrast mode
            : LinearGradient(
                colors: isDarkMode 
                  ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                  : [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        color: highContrastMode
            ? (isDarkMode ? Colors.black : Colors.white)
            : null,
        borderRadius: BorderRadius.circular(16),
        border: highContrastMode
            ? Border.all(color: isDarkMode ? Colors.white : Colors.black, width: 2.0)
            : null,
        boxShadow: highContrastMode
            ? null // No shadows in high contrast mode
            : [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isDarkMode ? const Color(0xFF8A4FFF) : const Color(0xFFE53935))
                  .withOpacity(0.1),
              ),
            ),
          ),
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
                    highContrastMode
                        ? Text(
                            'HopeCore Hub',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          )
                        : ShaderMask(
                            shaderCallback: (Rect bounds) {
                              return LinearGradient(
                                colors: isDarkMode 
                                  ? [const Color(0xFF8A4FFF), const Color(0xFF6D28D9)]
                                  : [const Color(0xFFE53935), const Color(0xFFD32F2F)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds);
                            },
                            child: const Text(
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
                        color: highContrastMode 
                            ? (isDarkMode ? Colors.black.withOpacity(0.7) : Colors.white.withOpacity(0.9))
                            : (isDarkMode ? const Color(0xFF0F172A).withOpacity(0.7) : Colors.white.withOpacity(0.9)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: LocalizedText(
                        'yourSafeSpaceForHealing',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 0.3,
                          color: highContrastMode 
                              ? (isDarkMode ? Colors.white70 : Colors.black87)
                              : Colors.white70,
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
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final highContrastMode = accessibilityProvider.highContrastMode;
    
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
              gradient: highContrastMode
                  ? null // No gradients in high contrast mode
                  : const LinearGradient(
                      colors: [Color(0xFFE53935), Color(0xFFC62828)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
              color: highContrastMode ? Colors.red : null,
              borderRadius: BorderRadius.circular(14),
              border: highContrastMode
                  ? Border.all(color: Colors.white, width: 3.0) // More prominent border for emergency buttons
                  : null,
              boxShadow: highContrastMode
                  ? null // No shadows in high contrast mode
                  : [
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
                        title: LocalizedText(
                          'emergencyCall',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        content: LocalizedText(
                          'wouldYouLikeToCallEmergencyServicesNow',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: LocalizedText(
                              'cancel',
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
                            child: LocalizedText(
                              'callNow',
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
                          color: highContrastMode ? Colors.white : Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.phone, 
                          color: highContrastMode ? Colors.red : Colors.white, 
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          LocalizedText(
                            'emergencyHelp',
                            style: TextStyle(
                              color: highContrastMode ? Colors.white : Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          LocalizedText(
                            'getImmediateSupport',
                            style: TextStyle(
                              color: highContrastMode ? Colors.white70 : Colors.white70,
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
                          color: highContrastMode ? Colors.white : Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_forward, 
                          color: highContrastMode ? Colors.red : Colors.white, 
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
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final highContrastMode = accessibilityProvider.highContrastMode;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            highContrastMode
                ? Icon(
                    Icons.bolt,
                    color: isDarkMode ? Colors.white : Colors.black,
                    size: 20,
                  )
                : ShaderMask(
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
                color: highContrastMode 
                    ? (isDarkMode ? Colors.white : Colors.black)
                    : (isDarkMode ? Colors.white : Colors.black87),
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
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final highContrastMode = accessibilityProvider.highContrastMode;
    
    // High contrast mode styling
    Color backgroundColor;
    Color textColor;
    Color iconColor;
    Color iconBackgroundColor;
    List<BoxShadow>? boxShadow;
    Gradient? gradient;
    Border? border;
    
    if (highContrastMode) {
      // High contrast mode: Use clear, strong colors with better visual hierarchy
      backgroundColor = AccessibilityUtils.getAccessibleSurfaceColor(context);
      textColor = AccessibilityUtils.getAccessibleColor(context, Colors.white);
      iconColor = isDarkMode ? Colors.black : Colors.white; // High contrast icon color
      iconBackgroundColor = isDarkMode ? Colors.white : Colors.black; // Strong icon background
      boxShadow = null; // No shadows in high contrast mode
      gradient = null; // No gradients in high contrast mode
      border = Border.all(
        color: AccessibilityUtils.getAccessibleBorderColor(context),
        width: 3.0, // Slightly thicker for better visibility
      );
    } else {
      // Normal mode: Use original gradient styling
      backgroundColor = color;
      textColor = Colors.white;
      iconColor = Colors.white;
      iconBackgroundColor = Colors.white.withOpacity(0.2);
      boxShadow = [
        BoxShadow(
          color: color.withOpacity(0.25),
          blurRadius: 10,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
      ];
      gradient = LinearGradient(
        colors: [
          color,
          Color.lerp(color, isDarkMode ? Colors.black : Colors.white, 0.3)!,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      border = null;
    }
    
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
          color: gradient == null ? backgroundColor : null,
          gradient: gradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: boxShadow,
          border: border,
        ),
        padding: EdgeInsets.all(highContrastMode ? 16 : 14), // More padding in high contrast for better visual breathing
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                borderRadius: BorderRadius.circular(highContrastMode ? 8 : 10),
                border: highContrastMode ? Border.all(
                  color: AccessibilityUtils.getAccessibleBorderColor(context),
                  width: 2.0, // Thicker border for icon container
                ) : null,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: highContrastMode ? 24 : 22, // Slightly larger icons in high contrast
              ),
            ),
            const Spacer(),
            Text(
              title,
              style: AccessibilityUtils.getTextStyle(
                context,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            SizedBox(height: highContrastMode ? 4 : 2), // More spacing in high contrast mode
            Text(
              subtitle,
              style: AccessibilityUtils.getTextStyle(
                context,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: highContrastMode ? textColor : textColor.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeelingsSection() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final highContrastMode = accessibilityProvider.highContrastMode;
    final primaryColor = isDarkMode ? const Color(0xFF8A4FFF) : const Color(0xFFE53935);
    
    return Container(
      decoration: BoxDecoration(
        gradient: highContrastMode
            ? null // No gradients in high contrast mode
            : LinearGradient(
                colors: isDarkMode 
                  ? [const Color(0xFF2A3B53), const Color(0xFF1E293B)]
                  : [const Color(0xFFFFEFEF), const Color(0xFFFAF0F0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        color: highContrastMode
            ? (isDarkMode ? Colors.black : Colors.white)
            : null,
        borderRadius: BorderRadius.circular(20),
        border: highContrastMode
            ? Border.all(color: isDarkMode ? Colors.white : Colors.black, width: 2.0)
            : null,
        boxShadow: highContrastMode
            ? null // No shadows in high contrast mode
            : [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: highContrastMode
                      ? null
                      : LinearGradient(
                          colors: isDarkMode 
                            ? [const Color(0xFF8A4FFF), const Color(0xFF6D28D9)]
                            : [const Color(0xFFE53935), const Color(0xFFD32F2F)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  color: highContrastMode
                      ? (isDarkMode ? Colors.white : Colors.black)
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  border: highContrastMode
                      ? Border.all(color: isDarkMode ? Colors.black : Colors.white, width: 2.0)
                      : null,
                  boxShadow: highContrastMode
                      ? null
                      : [
                    BoxShadow(
                      color: isDarkMode 
                        ? const Color(0xFF8A4FFF).withOpacity(0.3)
                        : const Color(0xFFE53935).withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.favorite,
                  color: highContrastMode
                      ? (isDarkMode ? Colors.black : Colors.white)
                      : Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // In high contrast mode, use standard text instead of animated text
              highContrastMode
                  ? Text(
                      AppLocalizations.of(context).translate('howAreYouFeelingToday'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    )
                  : AnimatedTextKit(
                      animatedTexts: [
                        TypewriterAnimatedText(
                          AppLocalizations.of(context).translate('howAreYouFeelingToday'),
                          textStyle: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                          speed: const Duration(milliseconds: 100),
                        ),
                      ],
                      totalRepeatCount: 1,
                      displayFullTextOnTap: true,
                    ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildEmotionButton('great', 0.1, isDarkMode, highContrastMode),
                _buildEmotionButton('good', 0.2, isDarkMode, highContrastMode),
                _buildEmotionButton('okay', 0.3, isDarkMode, highContrastMode),
                _buildEmotionButton('sad', 0.4, isDarkMode, highContrastMode),
                _buildEmotionButton('bad', 0.5, isDarkMode, highContrastMode),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionButton(String emotionKey, double delay, bool isDarkMode, bool highContrastMode) {
    final primaryColor = isDarkMode ? const Color(0xFF8A4FFF) : const Color(0xFFE53935);
    final localizations = AppLocalizations.of(context);
    final emotionLabel = localizations.translate(emotionKey);
    
    // Map emotion keys to emoji characters
    String getEmojiCharacter(String key) {
      switch (key) {
        case 'great':
          return '😀';
        case 'good':
          return '😊';
        case 'okay':
          return '😐';
        case 'sad':
          return '😔';
        case 'bad':
          return '😣';
        default:
          return '😊';
      }
    }
    
    // Get short text label for high contrast mode
    String getEmotionShortLabel(String key) {
      switch (key) {
        case 'great':
          return 'Great';
        case 'good':
          return 'Good';
        case 'okay':
          return 'Okay';
        case 'sad':
          return 'Sad';
        case 'bad':
          return 'Bad';
        default:
          return 'Good';
      }
    }
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final delayedAnimation = _animationController.drive(
          CurveTween(curve: Interval(0.4 + delay, 1.0, curve: Curves.elasticOut)),
        );
        
        // Ensure opacity is between 0.0 and 1.0
        final opacityValue = delayedAnimation.value.clamp(0.0, 1.0);
        
        return TweenAnimationBuilder(
          tween: Tween<double>(begin: 0.8, end: 1.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: 0.7 + (0.3 * delayedAnimation.value),
              child: Opacity(
                opacity: opacityValue,
                child: GestureDetector(
                  onTap: () => _playEmotionSelectAnimation(emotionKey),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: highContrastMode
                              ? null
                              : LinearGradient(
                                  colors: [
                                    isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                                    isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                          color: highContrastMode
                              ? (isDarkMode ? Colors.black : Colors.white)
                              : null,
                          borderRadius: BorderRadius.circular(16),
                          border: highContrastMode
                              ? Border.all(
                                  color: isDarkMode ? Colors.white : Colors.black,
                                  width: 2.0,
                                )
                              : null,
                          boxShadow: highContrastMode
                              ? null
                              : [
                            BoxShadow(
                              color: isDarkMode 
                                ? Colors.black.withOpacity(0.25) 
                                : primaryColor.withOpacity(0.15),
                              blurRadius: 10,
                              spreadRadius: 0,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: highContrastMode
                              // In high contrast mode, use text labels instead of emoji
                              ? Center(
                                  child: Text(
                                    getEmotionShortLabel(emotionKey),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode ? Colors.white : Colors.black,
                                    ),
                                  ),
                                )
                              : TweenAnimationBuilder<double>(
                                  tween: Tween<double>(begin: 0.8, end: 1.0),
                                  duration: const Duration(milliseconds: 800),
                                  curve: Curves.elasticOut,
                                  builder: (context, value, child) {
                                    return Transform.scale(
                                      scale: value,
                                      child: Text(
                                        getEmojiCharacter(emotionKey),
                                        style: const TextStyle(
                                          fontSize: 32,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        emotionLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: highContrastMode ? FontWeight.bold : FontWeight.w500,
                          color: highContrastMode
                              ? (isDarkMode ? Colors.white : Colors.black)
                              : (isDarkMode ? Colors.white70 : Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }
    );
  }
  
  void _playEmotionSelectAnimation(String emotionKey) {
    HapticFeedback.lightImpact();
    
    // Show emotion selection dialog instead of just a snackbar
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    final accentColor = isDarkMode ? const Color(0xFF8A4FFF) : const Color(0xFFE53935);
    final localizations = AppLocalizations.of(context);
    final emotionLabel = localizations.translate(emotionKey);
    
    // Map emotion keys to emoji characters
    String getEmojiCharacter(String key) {
      switch (key) {
        case 'great':
          return '😀';
        case 'good':
          return '😊';
        case 'okay':
          return '😐';
        case 'sad':
          return '😔';
        case 'bad':
          return '😣';
        default:
          return '😊';
      }
    }
    
    // Get appropriate color for each emotion
    Color getEmotionColor(String key) {
      switch (key) {
        case 'great':
          return const Color(0xFF4CAF50); // Green
        case 'good':
          return const Color(0xFF8BC34A); // Light Green
        case 'okay':
          return const Color(0xFFFFC107); // Amber
        case 'sad':
          return const Color(0xFFFF9800); // Orange
        case 'bad':
          return const Color(0xFFF44336); // Red
        default:
          return accentColor;
      }
    }
    
    // Get appropriate icon for each emotion
    IconData getEmotionIcon(String key) {
      switch (key) {
        case 'great':
          return Icons.sentiment_very_satisfied;
        case 'good':
          return Icons.sentiment_satisfied;
        case 'okay':
          return Icons.sentiment_neutral;
        case 'sad':
          return Icons.sentiment_dissatisfied;
        case 'bad':
          return Icons.sentiment_very_dissatisfied;
        default:
          return Icons.sentiment_neutral;
      }
    }
    
    final emotionColor = getEmotionColor(emotionKey);
    
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black87.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation1, animation2) => Container(), // This is needed but not used
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        // Create curved animations
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInBack,
        );
        
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation),
            child: Dialog(
              backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
              elevation: 12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    // Background decorations
                    Positioned(
                      top: -50,
                      right: -50,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: emotionColor.withOpacity(0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -60,
                      left: -30,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: emotionColor.withOpacity(0.15),
                        ),
                      ),
                    ),
                    
                    // Main content
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Close button
                          Align(
                            alignment: Alignment.topRight,
                            child: IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: (isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.05)),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close,
                                  color: isDarkMode ? Colors.white60 : Colors.black54,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                          
                          // Enhanced animated emoji
                          SizedBox(
                            height: 120,
                            child: Center(
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Pulsing background
                                  TweenAnimationBuilder<double>(
                                    tween: Tween<double>(begin: 0.8, end: 1.2),
                                    duration: const Duration(milliseconds: 2000),
                                    curve: Curves.easeInOut,
                                    builder: (context, value, child) {
                                      return Opacity(
                                        opacity: 0.2,
                                        child: Transform.scale(
                                          scale: value,
                                          child: Container(
                                            width: 100,
                                            height: 100,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: emotionColor,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  
                                  // Icon behind emoji
                                  TweenAnimationBuilder<double>(
                                    tween: Tween<double>(begin: 0.0, end: 1.0),
                                    duration: const Duration(milliseconds: 600),
                                    curve: Curves.easeOut,
                                    builder: (context, value, child) {
                                      return Opacity(
                                        opacity: value * 0.15,
                                        child: Transform.scale(
                                          scale: 2.5,
                                          child: Icon(
                                            getEmotionIcon(emotionKey),
                                            color: emotionColor,
                                            size: 40,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  
                                  // Emoji with bounce effect
                                  TweenAnimationBuilder<double>(
                                    tween: Tween<double>(begin: 0.5, end: 1.2),
                                    duration: const Duration(milliseconds: 1000),
                                    curve: Curves.elasticOut,
                                    builder: (context, value, child) {
                                      return Transform.scale(
                                        scale: value,
                                        child: Text(
                                          getEmojiCharacter(emotionKey),
                                          style: const TextStyle(
                                            fontSize: 70,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Title with animation
                          AnimatedTextKit(
                            animatedTexts: [
                              TypewriterAnimatedText(
                                'How can we support you today?',
                                textStyle: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                ),
                                speed: const Duration(milliseconds: 80),
                              ),
                            ],
                            totalRepeatCount: 1,
                            displayFullTextOnTap: true,
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Message
                          Text(
                            _getEmotionMessage(emotionKey),
                            style: TextStyle(
                              fontSize: 15,
                              color: isDarkMode ? Colors.white70 : Colors.black54,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Action buttons with ripple effect
                          Row(
                            children: [
                              Expanded(
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween<double>(begin: 0.0, end: 1.0),
                                  duration: const Duration(milliseconds: 600),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, value, child) {
                                    return Transform.translate(
                                      offset: Offset(0, 20 * (1 - value)),
                                      child: Opacity(
                                        opacity: value,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                            _navigateToPage(3); // Navigate to Mahoro
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: emotionColor,
                                            foregroundColor: Colors.white,
                                            elevation: 4,
                                            shadowColor: emotionColor.withOpacity(0.4),
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: const Text(
                                            'Talk to Mahoro',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween<double>(begin: 0.0, end: 1.0),
                                  duration: const Duration(milliseconds: 800), // Longer duration to create delay effect
                                  curve: const Interval(0.25, 1.0, curve: Curves.easeOutCubic), // Start at 25% to create delay
                                  builder: (context, value, child) {
                                    return Transform.translate(
                                      offset: Offset(0, 20 * (1 - value)),
                                      child: Opacity(
                                        opacity: value,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                            _navigateToPage(2); // Navigate to Forum
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.05),
                                            foregroundColor: isDarkMode ? Colors.white : Colors.black87,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: const Text(
                                            'Join Forum',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  String _getEmotionMessage(String emotionKey) {
    switch (emotionKey) {
      case 'great':
        return "It's great to see you're feeling good! Would you like to share your positive experiences or learn ways to maintain this mood?";
      case 'good':
        return "Sometimes we all feel a bit neutral. Would you like to talk about what's on your mind or explore ways to boost your mood?";
      case 'okay':
        return "Sometimes we all feel a bit neutral. Would you like to talk about what's on your mind or explore ways to boost your mood?";
      case 'sad':
        return "I'm sorry you're feeling down. Remember that it's okay to not be okay, and talking about it can help. Would you like some support?";
      case 'bad':
        return "I can see you're having a difficult time. Please remember you're not alone, and there are resources available to help you through this.";
      default:
        return "Thank you for sharing how you're feeling. Would you like to talk more about it?";
    }
  }
  
  Widget _buildResourcesSection() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final highContrastMode = accessibilityProvider.highContrastMode;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            highContrastMode 
                ? Icon(
                    Icons.category,
                    color: AccessibilityUtils.getAccessibleColor(context, Colors.white, isPrimary: true),
                    size: 22,
                  )
                : ShaderMask(
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
            LocalizedText(
              'resources',
              style: AccessibilityUtils.getTextStyle(
                context,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: highContrastMode 
                    ? AccessibilityUtils.getAccessibleColor(context, Colors.white)
                    : (isDarkMode ? Colors.white : Colors.black87),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildAnimatedResourceItem(
          color: Colors.red,
          icon: Icons.favorite,
          title: 'selfCareTips',
          subtitle: 'dailyWellnessPractices',
          delay: 0.1,
        ),
        const SizedBox(height: 10),
        _buildAnimatedResourceItem(
          color: Colors.blue,
          icon: Icons.shield_outlined,
          title: 'safetyPlanning',
          subtitle: 'personalSafetyResources',
          delay: 0.2,
        ),
        const SizedBox(height: 10),
        _buildAnimatedResourceItem(
          color: Colors.green,
          icon: Icons.call,
          title: 'crisisSupport',
          subtitle: 'helplineNumbers',
          delay: 0.3,
        ),
        const SizedBox(height: 10),
        _buildAnimatedResourceItem(
          color: Colors.purple,
          icon: Icons.menu_book,
          title: 'educationalContent',
          subtitle: 'learnAboutHealing',
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
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final highContrastMode = accessibilityProvider.highContrastMode;
    final localizations = AppLocalizations.of(context);
    
    return GestureDetector(
      onTap: () {
        // Get translated title for the popup
        String translatedTitle = localizations.translate(title);
        _playItemPressAnimation(translatedTitle);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: highContrastMode 
              ? AccessibilityUtils.getAccessibleSurfaceColor(context)
              : (isDarkMode ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: highContrastMode 
              ? Border.all(
                  color: AccessibilityUtils.getAccessibleBorderColor(context),
                  width: 2.0,
                )
              : null,
          boxShadow: highContrastMode 
              ? null // No shadows in high contrast mode
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: highContrastMode 
                    ? (isDarkMode ? Colors.white : Colors.black)
                    : color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: highContrastMode 
                    ? Border.all(
                        color: AccessibilityUtils.getAccessibleBorderColor(context),
                        width: 1.5,
                      )
                    : null,
              ),
              child: Icon(
                icon,
                color: highContrastMode 
                    ? (isDarkMode ? Colors.black : Colors.white)
                    : color,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LocalizedText(
                    title,
                    style: AccessibilityUtils.getTextStyle(
                      context,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: highContrastMode 
                          ? (isDarkMode ? Colors.white : Colors.black)
                          : (isDarkMode ? Colors.white : Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 2),
                  LocalizedText(
                    subtitle,
                    style: AccessibilityUtils.getTextStyle(
                      context,
                      fontSize: 12,
                      color: highContrastMode 
                          ? (isDarkMode ? Colors.white70 : Colors.black87)
                          : (isDarkMode ? Colors.white60 : Colors.black54),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: highContrastMode 
                  ? AccessibilityUtils.getAccessibleColor(context, Colors.white54)
                  : (isDarkMode ? Colors.white54 : Colors.black45),
              size: highContrastMode ? 16 : 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyAffirmationSection() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final highContrastMode = accessibilityProvider.highContrastMode;
    final primaryColor = isDarkMode ? const Color(0xFF8A4FFF) : const Color(0xFFE53935);
    
    return Container(
      padding: const EdgeInsets.all(0),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: highContrastMode 
            ? null // No gradients in high contrast mode
            : LinearGradient(
                colors: isDarkMode 
                  ? [const Color(0xFF2A205D), const Color(0xFF362C72)]
                  : [const Color(0xFFFFE1E0), const Color(0xFFFFF0F0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        color: highContrastMode 
            ? AccessibilityUtils.getAccessibleSurfaceColor(context)
            : null,
        border: highContrastMode 
            ? Border.all(
                color: AccessibilityUtils.getAccessibleBorderColor(context),
                                        width: 2.0,
              )
            : null,
        boxShadow: highContrastMode 
            ? null // No shadows in high contrast mode
            : [
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
                      color: highContrastMode 
                          ? (isDarkMode ? Colors.white : Colors.black)
                          : Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: highContrastMode 
                          ? Border.all(
                              color: AccessibilityUtils.getAccessibleBorderColor(context),
                              width: 2.0,
                            )
                          : null,
                    ),
                    child: Icon(
                      Icons.format_quote,
                      color: highContrastMode 
                          ? (isDarkMode ? Colors.black : Colors.white)
                          : (isDarkMode ? Colors.white : primaryColor),
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
                          style: AccessibilityUtils.getTextStyle(
                            context,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: highContrastMode 
                                ? (isDarkMode ? Colors.white : Colors.black)
                                : (isDarkMode ? Colors.white : primaryColor),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: highContrastMode 
                                ? AccessibilityUtils.getAccessibleSurfaceColor(context)
                                : Colors.white.withOpacity(isDarkMode ? 0.1 : 0.8),
                            borderRadius: BorderRadius.circular(10),
                            border: highContrastMode 
                                ? Border.all(
                                    color: AccessibilityUtils.getAccessibleBorderColor(context),
                                    width: 2.0,
                                  )
                                : null,
                            boxShadow: highContrastMode 
                                ? null // No shadows in high contrast mode
                                : [
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
                            style: AccessibilityUtils.getTextStyle(
                              context,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: highContrastMode 
                                  ? (isDarkMode ? Colors.white : Colors.black)
                                  : (isDarkMode ? Colors.white : Colors.black87),
                            ).copyWith(
                              fontStyle: FontStyle.italic,
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
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final highContrastMode = accessibilityProvider.highContrastMode;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: highContrastMode 
            ? null // No gradients in high contrast mode
            : LinearGradient(
                colors: [const Color(0xFF9B1C1C), const Color(0xFF771D1D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        color: highContrastMode 
            ? AccessibilityUtils.getAccessibleSurfaceColor(context)
            : null,
        borderRadius: BorderRadius.circular(14),
        border: highContrastMode 
            ? Border.all(
                color: AccessibilityUtils.getAccessibleBorderColor(context),
                width: 2.0,
              )
            : null,
        boxShadow: highContrastMode 
            ? null // No shadows in high contrast mode
            : [
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
                          color: highContrastMode 
                              ? (isDarkMode ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.2))
                              : Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.phone_enabled,
                          color: highContrastMode 
                              ? (isDarkMode ? Colors.black : Colors.white)
                              : Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Emergency Contacts',
                        style: AccessibilityUtils.getTextStyle(
                          context,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: highContrastMode 
                              ? (isDarkMode ? Colors.white : Colors.black)
                              : Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: highContrastMode 
                          ? (isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1))
                          : Colors.white.withOpacity(0.1),
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
                      color: highContrastMode 
                          ? (isDarkMode ? Colors.white.withOpacity(0.8) : Colors.black.withOpacity(0.8))
                          : Colors.white.withOpacity(0.8),
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final highContrastMode = accessibilityProvider.highContrastMode;
    
    return Container(
      height: 1,
      width: double.infinity,
      color: highContrastMode 
          ? (isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1))
          : Colors.white.withOpacity(0.1),
    );
  }
  
  Widget _buildEmergencyContact(String label, String number, IconData icon) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final highContrastMode = accessibilityProvider.highContrastMode;
    
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: highContrastMode 
                ? (isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1))
                : Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: highContrastMode 
                ? (isDarkMode ? Colors.white : Colors.black)
                : Colors.white,
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
                color: highContrastMode 
                    ? (isDarkMode ? Colors.white.withOpacity(0.8) : Colors.black.withOpacity(0.8))
                    : Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 1),
            Text(
              number,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: highContrastMode 
                    ? (isDarkMode ? Colors.white : Colors.black)
                    : Colors.white,
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
              color: highContrastMode 
                  ? (isDarkMode ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.2))
                  : Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.call,
              color: highContrastMode 
                  ? (isDarkMode ? Colors.white : Colors.black)
                  : Colors.white,
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
  
  void _playItemPressAnimation(String resourceTitle) {
    HapticFeedback.lightImpact();
    
    // Map translated titles to their respective cases for the switch statement
    String switchTitle = resourceTitle;
    
    // Handle different languages by mapping to English titles for the switch
    if (resourceTitle == 'Conseils d\'Auto-Soins' || 
        resourceTitle == 'Vidokezo vya Kujitunza' || 
        resourceTitle == 'Inama zo Kwita ku Buzima') {
      switchTitle = 'Self-Care Tips';
    } else if (resourceTitle == 'Planification de Sécurité' || 
               resourceTitle == 'Mpango wa Usalama' || 
               resourceTitle == 'Gahunda yo Kurinda Umutekano') {
      switchTitle = 'Safety Planning';
    } else if (resourceTitle == 'Soutien en Crise' || 
               resourceTitle == 'Msaada wa Dharura' || 
               resourceTitle == 'Gufasha mu Bihe Bikomeye') {
      switchTitle = 'Crisis Support';
    } else if (resourceTitle == 'Contenu Éducatif' || 
               resourceTitle == 'Maudhui ya Elimu' || 
               resourceTitle == 'Ibigisha') {
      switchTitle = 'Educational Content';
    }
    
    // Navigate to appropriate page based on the title
    if (resourceTitle == 'Forum') {
      _navigateToPage(2);
    } else if (resourceTitle == 'Mahoro') {
      _navigateToPage(3);
    } else if (resourceTitle == 'Muganga') {
      _navigateToPage(3); // Note: Muganga was removed from nav, keeping Mahoro
    } else if (resourceTitle == 'Settings') {
      _navigateToPage(4);
    } else {
      // Show resource dialog for other items
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      final isDarkMode = themeProvider.isDarkMode;
      
      // Get the resource color for animations and styling
      final resourceColor = _getResourceColor(switchTitle);
      
      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Dismiss',
        barrierColor: Colors.black87.withOpacity(0.6),
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation1, animation2) => Container(), // This is needed but not used
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          // Create curved animations
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
            reverseCurve: Curves.easeInBack,
          );
          
          return ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
            child: FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation),
              child: Dialog(
                backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                elevation: 12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      // Gradient background decoration
                      Positioned(
                        top: -50,
                        right: -50,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: resourceColor.withOpacity(0.1),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -60,
                        left: -30,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: resourceColor.withOpacity(0.15),
                          ),
                        ),
                      ),
                      
                      // Main content
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Header with icon and title
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: resourceColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _getResourceIcon(switchTitle),
                                    color: resourceColor,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    resourceTitle,
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  icon: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: (isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.05)),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.close,
                                      color: isDarkMode ? Colors.white60 : Colors.black54,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            // Divider
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Divider(
                                color: resourceColor.withOpacity(0.2),
                                thickness: 1,
                              ),
                            ),
                            
                            // Content with animation
                            AnimatedBuilder(
                              animation: animation,
                              builder: (context, child) {
                                // Staggered animation for list items
                                return Opacity(
                                  opacity: animation.value,
                                  child: child,
                                );
                              },
                              child: _buildResourceContent(switchTitle, isDarkMode, resourceColor),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Button with animation
                            AnimatedBuilder(
                              animation: animation,
                              builder: (context, child) {
                                // Animation for button - appears after content
                                final buttonAnimation = CurvedAnimation(
                                  parent: animation,
                                  curve: const Interval(0.6, 1.0, curve: Curves.elasticOut),
                                );
                                
                                return Transform.scale(
                                  scale: buttonAnimation.value,
                                  child: child,
                                );
                              },
                              child: SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: resourceColor,
                                    foregroundColor: Colors.white,
                                    elevation: 4,
                                    shadowColor: resourceColor.withOpacity(0.4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Got it',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    }
  }
  
  IconData _getResourceIcon(String resourceTitle) {
    switch (resourceTitle) {
      case 'Self-Care Tips':
        return Icons.favorite;
      case 'Safety Planning':
        return Icons.shield_outlined;
      case 'Crisis Support':
        return Icons.call;
      case 'Educational Content':
        return Icons.menu_book;
      default:
        return Icons.info_outline;
    }
  }
  
  Widget _buildResourceContent(String resourceTitle, bool isDarkMode, Color resourceColor) {
    // Customize content based on resource title
    switch (resourceTitle) {
      case 'Self-Care Tips':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResourceListItem(text: 'Practice deep breathing for 5 minutes', isDarkMode: isDarkMode, resourceColor: resourceColor, index: 0),
            _buildResourceListItem(text: 'Stay hydrated throughout the day', isDarkMode: isDarkMode, resourceColor: resourceColor, index: 1),
            _buildResourceListItem(text: 'Get at least 7-8 hours of sleep', isDarkMode: isDarkMode, resourceColor: resourceColor, index: 2),
            _buildResourceListItem(text: 'Take short breaks during work', isDarkMode: isDarkMode, resourceColor: resourceColor, index: 3),
            _buildResourceListItem(text: 'Connect with supportive friends and family', isDarkMode: isDarkMode, resourceColor: resourceColor, index: 4),
          ],
        );
      case 'Safety Planning':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResourceListItem(text: 'Identify safe locations you can go to', isDarkMode: isDarkMode, resourceColor: resourceColor, index: 0),
            _buildResourceListItem(text: 'Save emergency contact numbers', isDarkMode: isDarkMode, resourceColor: resourceColor, index: 1),
            _buildResourceListItem(text: 'Keep important documents accessible', isDarkMode: isDarkMode, resourceColor: resourceColor, index: 2),
            _buildResourceListItem(text: 'Create a code word with trusted friends', isDarkMode: isDarkMode, resourceColor: resourceColor, index: 3),
            _buildResourceListItem(text: 'Know the locations of local resources', isDarkMode: isDarkMode, resourceColor: resourceColor, index: 4),
          ],
        );
      case 'Crisis Support':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResourceListItem(text: 'Isange One Stop Center: 3029', isDarkMode: isDarkMode, resourceColor: resourceColor, index: 0),
            _buildResourceListItem(text: 'Rwanda National Police: 112', isDarkMode: isDarkMode, resourceColor: resourceColor, index: 1),
            _buildResourceListItem(text: 'RIB Hotline: 3512', isDarkMode: isDarkMode, resourceColor: resourceColor, index: 2),
            _buildResourceListItem(text: 'Mental Health Helpline: 114', isDarkMode: isDarkMode, resourceColor: resourceColor, index: 3),
            _buildResourceListItem(text: 'HopeCore Team: +250780332779', isDarkMode: isDarkMode, resourceColor: resourceColor, index: 4),
          ],
        );
      case 'Educational Content':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResourceListItem(text: 'Understanding trauma responses', isDarkMode: isDarkMode, resourceColor: resourceColor, index: 0),
            _buildResourceListItem(text: 'Recognizing healthy relationships', isDarkMode: isDarkMode, resourceColor: resourceColor, index: 1),
            _buildResourceListItem(text: 'Building resilience skills', isDarkMode: isDarkMode, resourceColor: resourceColor, index: 2),
            _buildResourceListItem(text: 'Managing anxiety and stress', isDarkMode: isDarkMode, resourceColor: resourceColor, index: 3),
            _buildResourceListItem(text: 'Supporting others in need', isDarkMode: isDarkMode, resourceColor: resourceColor, index: 4),
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
  
  Widget _buildResourceListItem({
    required String text, 
    required bool isDarkMode, 
    required Color resourceColor,
    required int index,
  }) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(20 * (1 - value), 0),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14.0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: resourceColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: resourceColor.withOpacity(0.15),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: resourceColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                color: resourceColor,
                size: 14,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ],
        ),
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
