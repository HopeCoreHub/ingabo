import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'theme_provider.dart';
import 'forum_page.dart';
import 'mahoro_page.dart';
import 'muganga_page.dart';
import 'settings_page.dart';
import 'auth_page.dart';
import 'services/auth_service.dart';
import 'services/forum_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Create auth service instance first
  final authService = AuthService();
  // Create forum service and set auth service
  final forumService = ForumService();
  forumService.setAuthService(authService);
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider.value(value: authService),
        Provider.value(value: forumService),
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
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF8A4FFF),
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
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, $username',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isGuest 
                    ? 'You are browsing as a guest'
                    : 'How are you feeling today?',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
            icon: Icon(
              Icons.settings_outlined,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
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
                      const SizedBox(height: 12),
                      FadeSlideTransition(
                        animation: _animationController,
                        begin: const Offset(0, -20),
                        delay: 0.0,
                        child: _buildHeader(),
                      ),
                      const SizedBox(height: 16),
                      FadeSlideTransition(
                        animation: _animationController,
                        begin: const Offset(0, -15),
                        delay: 0.05,
                        child: _buildUserGreeting(),
                      ),
                      const SizedBox(height: 20),
                      FadeSlideTransition(
                        animation: _animationController,
                        begin: const Offset(0, -10),
                        delay: 0.1,
                        child: _buildEmergencyButton(),
                      ),
                      const SizedBox(height: 24),
                      FadeSlideTransition(
                        animation: _animationController,
                        begin: const Offset(0, 0),
                        delay: 0.2,
                        child: _buildQuickAccessSection(),
                      ),
                      const SizedBox(height: 24),
                      FadeSlideTransition(
                        animation: _animationController,
                        begin: const Offset(0, 10),
                        delay: 0.3,
                        child: _buildFeelingsSection(),
                      ),
                      const SizedBox(height: 24),
                      FadeSlideTransition(
                        animation: _animationController,
                        begin: const Offset(0, 10),
                        delay: 0.4,
                        child: _buildResourcesSection(),
                      ),
                      const SizedBox(height: 24),
                      FadeSlideTransition(
                        animation: _animationController,
                        begin: const Offset(0, 10),
                        delay: 0.5,
                        child: _buildDailyAffirmationSection(),
                      ),
                      const SizedBox(height: 24),
                      FadeSlideTransition(
                        animation: _animationController,
                        begin: const Offset(0, 10),
                        delay: 0.6,
                        child: _buildEmergencyContactsSection(),
                      ),
                      const SizedBox(height: 24),
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
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Profile button
        Hero(
          tag: 'profile_button',
          child: GestureDetector(
            onTap: () {
              // Use MainNavigationWrapper to keep the bottom navigation bar
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const MainNavigationWrapper(
                    selectedIndex: 0,  // Keep on Home tab
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
              ),
              child: Icon(
                Icons.person_outline,
                color: isDarkMode ? const Color(0xFF111827) : Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
        
        // Logo and title
        Column(
          children: [
            Hero(
              tag: 'app_logo',
              child: Container(
                width: 100,
                height: 100,
                child: Image.asset(
                  'assets/logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'HopeCore Hub',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? const Color(0xFF8A4FFF) : const Color(0xFFE53935),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Your safe space for healing and support',
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
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
                color: Colors.transparent,
                border: Border.all(
                  color: isDarkMode ? Colors.white12 : Colors.black12,
                ),
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
    );
  }

  Widget _buildEmergencyButton() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: () {
          _playButtonPressAnimation();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE53935),  // Keep emergency button red in both themes
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        icon: const Icon(Icons.phone, color: Colors.white),
        label: const Text(
          'SOS - Emergency Help',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAccessSection() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Access',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildAnimatedQuickAccessItem(
                color: const Color(0xFFB066FD),
                icon: Icons.chat_bubble_outline,
                title: 'Forum',
                subtitle: 'Connect with community',
                delay: 0.1,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildAnimatedQuickAccessItem(
                color: const Color(0xFF3B82F6),
                icon: Icons.business_center_outlined,
                title: 'Mahoro',
                subtitle: 'AI Support Companion',
                delay: 0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildAnimatedQuickAccessItem(
                color: const Color(0xFF10B981),
                icon: Icons.people_outline,
                title: 'Muganga',
                subtitle: 'Professional Support',
                delay: 0.3,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildAnimatedQuickAccessItem(
                color: const Color(0xFF6B7280),
                icon: Icons.settings_outlined,
                title: 'Settings',
                subtitle: 'Customize your experience',
                delay: 0.4,
              ),
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
          CurveTween(curve: Interval(delay, 1.0, curve: Curves.easeOut)),
        );
        return Transform.scale(
          scale: 0.9 + (0.1 * delayedAnimation.value),
          child: Opacity(
            opacity: delayedAnimation.value,
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.white60 : Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeelingsSection() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.favorite,
                color: isDarkMode ? const Color(0xFF8A4FFF) : const Color(0xFFE53935),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'How are you feeling today?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? const Color(0xFF8A4FFF) : const Color(0xFFE53935),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildEmotionButton('😀', 0.1, isDarkMode),
              _buildEmotionButton('😐', 0.2, isDarkMode),
              _buildEmotionButton('😔', 0.3, isDarkMode),
              _buildEmotionButton('😣', 0.4, isDarkMode),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionButton(String emotion, double delay, bool isDarkMode) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final delayedAnimation = _animationController.drive(
          CurveTween(curve: Interval(0.4 + delay, 1.0, curve: Curves.easeOut)),
        );
        
        return Transform.scale(
          scale: 0.8 + (0.2 * delayedAnimation.value),
          child: Opacity(
            opacity: delayedAnimation.value,
            child: GestureDetector(
              onTap: () => _playEmotionSelectAnimation(emotion),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
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
        Text(
          'Resources',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        _buildAnimatedResourceItem(
          color: Colors.red,
          icon: Icons.favorite,
          title: 'Self-Care Tips',
          subtitle: 'Daily wellness practices',
          delay: 0.1,
        ),
        const SizedBox(height: 12),
        _buildAnimatedResourceItem(
          color: Colors.blue,
          icon: Icons.shield_outlined,
          title: 'Safety Planning',
          subtitle: 'Personal safety resources',
          delay: 0.2,
        ),
        const SizedBox(height: 12),
        _buildAnimatedResourceItem(
          color: Colors.green,
          icon: Icons.call,
          title: 'Crisis Support',
          subtitle: '24/7 helpline numbers',
          delay: 0.3,
        ),
        const SizedBox(height: 12),
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
          CurveTween(curve: Interval(0.3 + delay, 1.0, curve: Curves.easeOut)),
        );
        
        return Transform.translate(
          offset: Offset(20 - (20 * delayedAnimation.value), 0),
          child: Opacity(
            opacity: delayedAnimation.value,
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyAffirmationSection() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            'Daily Affirmation',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? const Color(0xFF8A4FFF) : const Color(0xFFE53935),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '"You are stronger than you know, braver than you feel, and more loved than you imagine."',
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactsSection() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF6B1D1D),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const Text(
            'In case of emergency:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          _buildEmergencyContact('Isange One Stop Center:', '3029'),
          const SizedBox(height: 4),
          _buildEmergencyContact('Rwanda National Police:', '3512'),
          const SizedBox(height: 4),
          _buildEmergencyContact('HopeCore Team:', '+250780332779'),
        ],
      ),
    );
  }

  Widget _buildEmergencyContact(String label, String number) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          number,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
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
    
    // Here we would handle the animation for selecting an emotion
    // You could add custom animations or haptic feedback
    
    // For now, just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('You selected: $emotion'),
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
      // Handle other items or show a "coming soon" message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$resourceTitle coming soon'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
      ),
    );
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
        // Simple snackbar instead of full implementation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Calling $number...'),
            duration: const Duration(seconds: 1),
          ),
        );
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
  
  // Method to handle sending text messages
  void _sendTextMessage() {
    // Simple snackbar instead of full implementation
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
        content: Text('Opening messaging app...'),
        duration: Duration(seconds: 1),
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
        return Opacity(
          opacity: delayedAnimation.value,
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
