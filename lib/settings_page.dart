import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'services/auth_service.dart';
import 'auth_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Settings state
  String _fontFamily = 'Inter (Default)';
  String _fontSize = 'Medium (Default)';
  bool _highContrastMode = false;
  bool _reduceMotion = false;
  String _appLanguage = 'English';
  bool _textToSpeech = false;
  bool _voiceToText = false;
  bool _lowDataMode = false;
  bool _imageLazyLoading = false;
  bool _offlineMode = false;
  bool _forumReplies = true;
  bool _weeklyCheckIns = true;
  bool _systemUpdates = false;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final accentColor = isDarkMode ? const Color(0xFF8A4FFF) : const Color(0xFFE53935);
    
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF111827) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        title: Text(
          'Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        automaticallyImplyLeading: false,
        systemOverlayStyle: isDarkMode ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: Icon(
                Icons.search, 
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
              onPressed: () {
                // Show search dialog
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileHeader(),
              const SizedBox(height: 16),
              _buildAccessibilitySection(),
              const SizedBox(height: 16),
              _buildLanguageAudioSection(),
              const SizedBox(height: 16),
              _buildDataPerformanceSection(),
              const SizedBox(height: 16),
              _buildAppearanceSection(),
              const SizedBox(height: 16),
              _buildNotificationsSection(),
              const SizedBox(height: 16),
              _buildPrivacySecuritySection(),
              const SizedBox(height: 16),
              _buildEmergencyContactsSection(),
              const SizedBox(height: 16),
              _buildFooter(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authService = Provider.of<AuthService>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    // Get user information
    final username = authService.username ?? 'Guest User';
    final userId = authService.userId ?? 'No ID';
    
    // Define isGuest based on authentication status
    final bool isGuest = !authService.isLoggedIn || authService.username == null;
    
    // Get first letter of username for avatar
    final String firstLetter = username[0].toUpperCase();
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8A4FFF), Color(0xFF9667FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8A4FFF).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Center(
              child: Text(
                firstLetter,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
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
                  username,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isGuest ? Colors.amber : const Color(0xFF4ADE80),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isGuest ? 'Guest Mode' : 'Online',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              // Show edit profile or login dialog
              if (isGuest) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AuthPage()),
                );
              } else {
                // Show edit profile dialog or navigate to profile page
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isGuest ? 'Sign In' : 'Edit Profile',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final accentColor = isDarkMode ? const Color(0xFF8A4FFF) : const Color(0xFFE53935);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                icon,
                color: accentColor,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required String title,
    required Widget child,
    String? description,
    IconData? leadingIcon,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (leadingIcon != null) ...[
            Icon(
              leadingIcon,
              color: const Color(0xFF8A4FFF),
              size: 20,
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
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
                if (description != null && description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDarkMode ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildDropdownSetting(String title, String value, String description, {IconData? icon}) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return _buildSettingItem(
      title: title,
      description: description,
      leadingIcon: icon,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF111827) : Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              color: isDarkMode ? Colors.white54 : Colors.black54,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchSetting(String title, String description, bool value, Function(bool) onChanged, {IconData? icon}) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final accentColor = isDarkMode ? const Color(0xFF8A4FFF) : const Color(0xFFE53935);

    return _buildSettingItem(
      title: title,
      description: description,
      leadingIcon: icon,
      child: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.white,
        activeTrackColor: accentColor,
        inactiveThumbColor: Colors.grey,
        inactiveTrackColor: Colors.grey.withOpacity(0.3),
      ),
    );
  }

  Widget _buildLinkSetting(String title, {IconData? icon}) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return _buildSettingItem(
      title: title,
      leadingIcon: icon,
      description: '',
      child: Icon(
        Icons.arrow_forward_ios,
        color: isDarkMode ? Colors.white54 : Colors.black54,
        size: 16,
      ),
    );
  }

  Widget _buildSectionCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildAccessibilitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Accessibility', Icons.settings_accessibility),
        _buildSectionCard([
          _buildDropdownSetting(
            'Font Family',
            _fontFamily,
            'Choose a font that\'s comfortable for reading',
            icon: Icons.font_download_outlined,
          ),
          _buildDropdownSetting(
            'Font Size',
            _fontSize,
            'Adjust text size for better readability',
            icon: Icons.format_size,
          ),
          _buildSwitchSetting(
            'High Contrast Mode',
            'Increase contrast for better visibility',
            _highContrastMode,
            (value) => setState(() => _highContrastMode = value),
            icon: Icons.contrast,
          ),
          _buildSwitchSetting(
            'Reduce Motion',
            'Minimize animations and transitions',
            _reduceMotion,
            (value) => setState(() => _reduceMotion = value),
            icon: Icons.animation,
          ),
        ]),
      ],
    );
  }

  Widget _buildLanguageAudioSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Language & Audio', Icons.language),
        _buildSectionCard([
          _buildDropdownSetting(
            'App Language',
            'English',
            'Choose your preferred language',
            icon: Icons.translate,
          ),
          _buildSwitchSetting(
            'Text-to-Speech',
            'Convert text to spoken audio',
            _textToSpeech,
            (value) => setState(() => _textToSpeech = value),
            icon: Icons.record_voice_over,
          ),
          _buildSwitchSetting(
            'Voice-to-Text',
            'Convert speech to written text',
            _voiceToText,
            (value) => setState(() => _voiceToText = value),
            icon: Icons.keyboard_voice,
          ),
        ]),
      ],
    );
  }

  Widget _buildDataPerformanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Data & Performance', Icons.data_usage),
        _buildSectionCard([
          _buildSwitchSetting(
            'Low Data Mode',
            'Reduce data usage for remote areas',
            _lowDataMode,
            (value) => setState(() => _lowDataMode = value),
            icon: Icons.data_saver_off,
          ),
          _buildSwitchSetting(
            'Image Lazy Loading',
            'Load images only when needed',
            _imageLazyLoading,
            (value) => setState(() => _imageLazyLoading = value),
            icon: Icons.image,
          ),
          _buildSwitchSetting(
            'Offline Mode',
            'Cache content for offline access',
            _offlineMode,
            (value) => setState(() => _offlineMode = value),
            icon: Icons.cloud_off,
          ),
        ]),
      ],
    );
  }

  Widget _buildAppearanceSection() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Appearance', Icons.palette_outlined),
        _buildSectionCard([
          _buildSwitchSetting(
            'Dark Mode',
            'Use dark theme throughout the app',
            themeProvider.isDarkMode,
            (value) {
              themeProvider.toggleDarkMode(value);
            },
            icon: Icons.dark_mode,
          ),
        ]),
      ],
    );
  }

  Widget _buildNotificationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Notifications', Icons.notifications_outlined),
        _buildSectionCard([
          _buildSwitchSetting(
            'Forum Replies',
            'Get notified of new replies',
            _forumReplies,
            (value) => setState(() => _forumReplies = value),
            icon: Icons.chat_bubble_outline,
          ),
          _buildSwitchSetting(
            'Weekly Check-Ins',
            'Mental health reminders',
            _weeklyCheckIns,
            (value) => setState(() => _weeklyCheckIns = value),
            icon: Icons.event_note,
          ),
          _buildSwitchSetting(
            'System Updates',
            'App updates and news',
            _systemUpdates,
            (value) => setState(() => _systemUpdates = value),
            icon: Icons.system_update,
          ),
        ]),
      ],
    );
  }

  Widget _buildPrivacySecuritySection() {
    final authService = Provider.of<AuthService>(context);
    final isLoggedIn = authService.isLoggedIn;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Privacy & Security', Icons.shield_outlined),
        _buildSectionCard([
          _buildLinkSetting('Privacy Policy', icon: Icons.privacy_tip),
          _buildLinkSetting('Terms of Service', icon: Icons.description),
          _buildLinkSetting('Data & Privacy Settings', icon: Icons.settings_applications),
          if (isLoggedIn) _buildLogoutButton(),
        ]),
      ],
    );
  }

  Widget _buildLogoutButton() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return GestureDetector(
      onTap: () => _showLogoutConfirmation(),
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.red.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.logout,
              color: Colors.red,
              size: 20,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.red,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Sign out from your account',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDarkMode ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.red,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
  
  void _showLogoutConfirmation() {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await authService.logout();
              
              // Navigate to auth page
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AuthPage()),
                );
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactsSection() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6B1D1D), Color(0xFF8B2121)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B1D1D).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.emergency,
                color: Colors.white,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Emergency Contacts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildEmergencyContact('Isange One Stop Center', '3029'),
          const SizedBox(height: 8),
          _buildEmergencyContact('Rwanda National Police', '3512'),
          const SizedBox(height: 8),
          _buildEmergencyContact('HopeCore Team', '+250780332779'),
        ],
      ),
    );
  }

  Widget _buildEmergencyContact(String label, String number) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          Row(
            children: [
              Text(
                number,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.call,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'assets/logo.png',
            width: 40,
            height: 40,
          ),
          const SizedBox(height: 12),
          Text(
            'HopeCore Hub v1.0.0',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Built with love for survivors and their healing journey ❤️',
            style: TextStyle(
              fontSize: 12,
              color: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
} 