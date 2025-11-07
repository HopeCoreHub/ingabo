import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme_provider.dart';
import 'language_provider.dart';
import 'accessibility_provider.dart';
import 'data_performance_provider.dart';
import 'notification_provider.dart';
import 'services/auth_service.dart';
import 'auth_page.dart';
import 'firebase_import_page.dart';
import 'localization/app_localizations.dart';
import 'localization/localized_text.dart';
import 'localization/base_screen.dart';
import 'admin_page.dart';
import 'package:firebase_database/firebase_database.dart';
import 'utils/accessibility_utils.dart';
import 'pages/privacy_policy_page.dart';
import 'pages/terms_of_service_page.dart';
import 'pages/data_privacy_settings_page.dart';

class SettingsPage extends BaseScreen {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends BaseScreenState<SettingsPage> {
  bool _isAdmin = false;
  bool _isCheckingAdmin = true;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  // Check if the current user has admin privileges
  Future<void> _checkAdminStatus() async {
    final authService = Provider.of<AuthService>(context, listen: false);

    if (authService.isLoggedIn && authService.userId != null) {
      try {
        // Check admin status in Firebase Realtime Database
        final userId = authService.userId!;
        final DatabaseReference databaseRef = FirebaseDatabase.instance.ref();
        final snapshot = await databaseRef.child('admins').child(userId).get();

        if (mounted) {
          setState(() {
            _isAdmin = snapshot.exists && snapshot.value == true;
            _isCheckingAdmin = false;
          });
        }
      } catch (e) {
        debugPrint('Error checking admin status: $e');
        if (mounted) {
          setState(() {
            _isAdmin = false;
            _isCheckingAdmin = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isAdmin = false;
          _isCheckingAdmin = false;
        });
      }
    }
  }

  @override
  Widget buildScreen(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final highContrastMode = accessibilityProvider.highContrastMode;
    final accentColor =
        isDarkMode ? const Color(0xFF8A4FFF) : const Color(0xFFE53935);
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor:
          (highContrastMode && isDarkMode)
              ? Colors.black
              : (isDarkMode ? const Color(0xFF111827) : Colors.white),
      appBar: AppBar(
        backgroundColor:
            (highContrastMode && isDarkMode)
                ? Colors.black
                : (isDarkMode ? const Color(0xFF1E293B) : Colors.white),
        elevation: 0,
        title: LocalizedText(
          'settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        automaticallyImplyLeading: false,
        systemOverlayStyle:
            isDarkMode ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
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
                _showSearchDialog();
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
              const SizedBox(height: 12),
              _buildAccessibilitySection(),
              const SizedBox(height: 12),
              _buildLanguageAudioSection(),
              const SizedBox(height: 12),
              _buildDataPerformanceSection(),
              const SizedBox(height: 12),
              _buildAppearanceSection(),
              const SizedBox(height: 12),
              _buildNotificationsSection(),
              const SizedBox(height: 12),
              _buildPrivacySecuritySection(),
              const SizedBox(height: 12),
              _buildContentPolicySection(),
              const SizedBox(height: 12),
              if (_isAdmin) ...[
                _buildAdminSection(),
                const SizedBox(height: 12),
              ],
              _buildDatabaseSection(),
              const SizedBox(height: 12),
              _buildEmergencyContactsSection(),
              const SizedBox(height: 12),
              _buildFooter(),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return buildScreen(context);
  }

  void _showSearchDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final accessibilityProvider = Provider.of<AccessibilityProvider>(
      context,
      listen: false,
    );
    final isDarkMode = themeProvider.isDarkMode;
    final highContrastMode = accessibilityProvider.highContrastMode;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor:
              highContrastMode
                  ? AccessibilityUtils.getAccessibleSurfaceColor(context)
                  : (isDarkMode ? const Color(0xFF1E293B) : Colors.white),
          shape:
              highContrastMode
                  ? RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: AccessibilityUtils.getAccessibleBorderColor(
                        context,
                      ),
                      width: 3.0,
                    ),
                  )
                  : null,
          title: LocalizedText(
            'searchSettings',
            style: AccessibilityUtils.getTextStyle(
              context,
              fontWeight: FontWeight.bold,
              color:
                  highContrastMode
                      ? AccessibilityUtils.getAccessibleColor(
                        context,
                        isDarkMode ? Colors.white : Colors.black87,
                      )
                      : (isDarkMode ? Colors.white : Colors.black87),
            ),
          ),
          content: TextField(
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search settings...',
              hintStyle: AccessibilityUtils.getTextStyle(
                context,
                color:
                    highContrastMode
                        ? AccessibilityUtils.getAccessibleColor(
                          context,
                          isDarkMode ? Colors.white54 : Colors.black54,
                        )
                        : (isDarkMode ? Colors.white54 : Colors.black54),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    highContrastMode
                        ? BorderSide(
                          color: AccessibilityUtils.getAccessibleBorderColor(
                            context,
                          ),
                          width: 2.0,
                        )
                        : const BorderSide(),
              ),
              prefixIcon: Icon(
                Icons.search,
                color:
                    highContrastMode
                        ? AccessibilityUtils.getAccessibleColor(
                          context,
                          isDarkMode ? Colors.white54 : Colors.black54,
                        )
                        : (isDarkMode ? Colors.white54 : Colors.black54),
              ),
            ),
            style: AccessibilityUtils.getTextStyle(
              context,
              color:
                  highContrastMode
                      ? AccessibilityUtils.getAccessibleColor(
                        context,
                        isDarkMode ? Colors.white : Colors.black87,
                      )
                      : (isDarkMode ? Colors.white : Colors.black87),
            ),
            onChanged: (value) {
              // Search functionality can be implemented here
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: LocalizedText(
                'cancel',
                style: AccessibilityUtils.getTextStyle(
                  context,
                  color:
                      highContrastMode
                          ? AccessibilityUtils.getAccessibleColor(
                            context,
                            isDarkMode ? Colors.white60 : Colors.black54,
                          )
                          : (isDarkMode ? Colors.white60 : Colors.black54),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileHeader() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
    final authService = Provider.of<AuthService>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final highContrastMode = accessibilityProvider.highContrastMode;

    // Get user information
    final username = authService.username ?? 'Guest User';
    final userId = authService.userId ?? 'No ID';

    // Define isGuest based on authentication status
    final bool isGuest =
        !authService.isLoggedIn || authService.username == null;

    // Get first letter of username for avatar
    final String firstLetter = username[0].toUpperCase();

    return Container(
      margin: EdgeInsets.fromLTRB(16, 12, 16, 12),
      padding: EdgeInsets.all(highContrastMode ? 18 : 16),
      decoration: BoxDecoration(
        gradient:
            highContrastMode
                ? null // No gradients in high contrast mode
                : const LinearGradient(
                  colors: [Color(0xFF8A4FFF), Color(0xFF9667FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
        color:
            highContrastMode
                ? AccessibilityUtils.getAccessibleSurfaceColor(context)
                : null,
        borderRadius: BorderRadius.circular(14),
        border:
            highContrastMode
                ? Border.all(
                  color: AccessibilityUtils.getAccessibleBorderColor(context),
                  width: 3.0, // Thick border for profile section
                )
                : null,
        boxShadow:
            highContrastMode
                ? null // No shadows in high contrast mode
                : [
                  BoxShadow(
                    color: const Color(0xFF8A4FFF).withOpacity(0.25),
                    blurRadius: 12,
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
              color:
                  highContrastMode
                      ? (isDarkMode ? Colors.white : Colors.black)
                      : null,
              border: Border.all(
                color:
                    highContrastMode
                        ? AccessibilityUtils.getAccessibleBorderColor(context)
                        : Colors.white,
                width: highContrastMode ? 3 : 2,
              ),
            ),
            child: Center(
              child: Text(
                firstLetter,
                style: AccessibilityUtils.getTextStyle(
                  context,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color:
                      highContrastMode
                          ? (isDarkMode ? Colors.black : Colors.white)
                          : Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(width: highContrastMode ? 16 : 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  username,
                  style: AccessibilityUtils.getTextStyle(
                    context,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color:
                        highContrastMode
                            ? AccessibilityUtils.getAccessibleColor(
                              context,
                              Colors.white,
                            )
                            : Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      width: highContrastMode ? 9 : 7,
                      height: highContrastMode ? 9 : 7,
                      decoration: BoxDecoration(
                        color:
                            highContrastMode
                                ? (isDarkMode ? Colors.white : Colors.black)
                                : (isGuest
                                    ? Colors.amber
                                    : const Color(0xFF4ADE80)),
                        shape: BoxShape.circle,
                        border:
                            highContrastMode
                                ? Border.all(
                                  color:
                                      AccessibilityUtils.getAccessibleBorderColor(
                                        context,
                                      ),
                                  width: 1.5,
                                )
                                : null,
                      ),
                    ),
                    SizedBox(width: highContrastMode ? 7 : 5),
                    Text(
                      isGuest ? 'Guest Mode' : 'Online',
                      style: AccessibilityUtils.getTextStyle(
                        context,
                        fontSize: 12,
                        color:
                            highContrastMode
                                ? AccessibilityUtils.getAccessibleColor(
                                  context,
                                  Colors.white70,
                                )
                                : Colors.white70,
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
              padding: EdgeInsets.symmetric(
                horizontal: highContrastMode ? 12 : 10,
                vertical: highContrastMode ? 7 : 5,
              ),
              decoration: BoxDecoration(
                color:
                    highContrastMode
                        ? (isDarkMode ? Colors.white : Colors.black)
                        : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border:
                    highContrastMode
                        ? Border.all(
                          color: AccessibilityUtils.getAccessibleBorderColor(
                            context,
                          ),
                          width: 2.0,
                        )
                        : null,
              ),
              child: Text(
                isGuest ? 'Sign In' : 'Edit Profile',
                style: AccessibilityUtils.getTextStyle(
                  context,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color:
                      highContrastMode
                          ? (isDarkMode ? Colors.black : Colors.white)
                          : Colors.white,
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
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final highContrastMode = accessibilityProvider.highContrastMode;
    final accentColor =
        isDarkMode ? const Color(0xFF8A4FFF) : const Color(0xFFE53935);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: highContrastMode ? 10 : 8,
      ),
      child: Row(
        children: [
          Container(
            width: highContrastMode ? 36 : 32,
            height: highContrastMode ? 36 : 32,
            decoration: BoxDecoration(
              color:
                  highContrastMode
                      ? (isDarkMode ? Colors.white : Colors.black)
                      : accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border:
                  highContrastMode
                      ? Border.all(
                        color: AccessibilityUtils.getAccessibleBorderColor(
                          context,
                        ),
                        width: 2.0,
                      )
                      : null,
            ),
            child: Center(
              child: Icon(
                icon,
                color:
                    highContrastMode
                        ? (isDarkMode ? Colors.black : Colors.white)
                        : accentColor,
                size: highContrastMode ? 18 : 16,
              ),
            ),
          ),
          SizedBox(width: highContrastMode ? 12 : 10),
          LocalizedText(
            title.toLowerCase().replaceAll(' & ', ''),
            style: AccessibilityUtils.getTextStyle(
              context,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color:
                  highContrastMode
                      ? AccessibilityUtils.getAccessibleColor(
                        context,
                        Colors.white,
                      )
                      : (isDarkMode ? Colors.white : Colors.black87),
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
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final highContrastMode = accessibilityProvider.highContrastMode;

    return Container(
      margin: EdgeInsets.only(bottom: highContrastMode ? 14 : 12),
      padding: EdgeInsets.symmetric(
        horizontal: highContrastMode ? 18 : 16,
        vertical: highContrastMode ? 14 : 12,
      ),
      decoration: BoxDecoration(
        color:
            highContrastMode
                ? AccessibilityUtils.getAccessibleSurfaceColor(context)
                : (isDarkMode
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF1F5F9)),
        borderRadius: BorderRadius.circular(12),
        border:
            highContrastMode
                ? Border.all(
                  color: AccessibilityUtils.getAccessibleBorderColor(context),
                  width: 2.0,
                )
                : null,
      ),
      child: Row(
        children: [
          if (leadingIcon != null) ...[
            Icon(
              leadingIcon,
              color:
                  highContrastMode
                      ? AccessibilityUtils.getAccessibleColor(
                        context,
                        const Color(0xFF8A4FFF),
                        isPrimary: true,
                      )
                      : const Color(0xFF8A4FFF),
              size: highContrastMode ? 22 : 20,
            ),
            SizedBox(width: highContrastMode ? 18 : 16),
          ],
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
                    color:
                        highContrastMode
                            ? AccessibilityUtils.getAccessibleColor(
                              context,
                              Colors.white,
                            )
                            : (isDarkMode ? Colors.white : Colors.black87),
                  ),
                ),
                if (description != null && description.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: highContrastMode ? 6 : 4),
                    child: Text(
                      description,
                      style: AccessibilityUtils.getTextStyle(
                        context,
                        fontSize: 13,
                        color:
                            highContrastMode
                                ? AccessibilityUtils.getAccessibleColor(
                                  context,
                                  Colors.white60,
                                )
                                : (isDarkMode
                                    ? Colors.white60
                                    : Colors.black54),
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

  Widget _buildDropdownSetting(
    String title,
    String value,
    String description, {
    IconData? icon,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final highContrastMode = accessibilityProvider.highContrastMode;

    return _buildSettingItem(
      title: title,
      description: description,
      leadingIcon: icon,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              highContrastMode
                  ? AccessibilityUtils.getAccessibleSurfaceColor(context)
                  : (isDarkMode ? const Color(0xFF111827) : Colors.white),
          borderRadius: BorderRadius.circular(8),
          border:
              highContrastMode
                  ? Border.all(
                    color: AccessibilityUtils.getAccessibleBorderColor(context),
                    width: 2.0,
                  )
                  : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color:
                    highContrastMode
                        ? AccessibilityUtils.getAccessibleColor(
                          context,
                          isDarkMode ? Colors.white70 : Colors.black87,
                        )
                        : (isDarkMode ? Colors.white70 : Colors.black87),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              color:
                  highContrastMode
                      ? AccessibilityUtils.getAccessibleColor(
                        context,
                        isDarkMode ? Colors.white54 : Colors.black54,
                      )
                      : (isDarkMode ? Colors.white54 : Colors.black54),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchSetting(
    String title,
    String description,
    bool value,
    Function(bool) onChanged, {
    IconData? icon,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final highContrastMode = accessibilityProvider.highContrastMode;
    final accentColor =
        isDarkMode ? const Color(0xFF8A4FFF) : const Color(0xFFE53935);

    return _buildSettingItem(
      title: title,
      description: description,
      leadingIcon: icon,
      child: Switch(
        value: value,
        onChanged: onChanged,
        activeColor:
            highContrastMode
                ? (isDarkMode ? Colors.black : Colors.white)
                : Colors.white,
        activeTrackColor:
            highContrastMode
                ? (isDarkMode ? Colors.white : Colors.black)
                : accentColor,
        inactiveThumbColor:
            highContrastMode
                ? (isDarkMode ? Colors.white : Colors.black)
                : Colors.grey,
        inactiveTrackColor:
            highContrastMode
                ? (isDarkMode ? Colors.black : Colors.white).withOpacity(0.5)
                : Colors.grey.withOpacity(0.3),
      ),
    );
  }

  Widget _buildLinkSetting(String title, {IconData? icon}) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return GestureDetector(
      onTap: () => _handleLinkSettingTap(title),
      child: _buildSettingItem(
        title: title,
        leadingIcon: icon,
        description: '',
        child: Icon(
          Icons.arrow_forward_ios,
          color: isDarkMode ? Colors.white54 : Colors.black54,
          size: 16,
        ),
      ),
    );
  }

  void _handleLinkSettingTap(String title) {
    switch (title) {
      case 'Privacy Policy':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PrivacyPolicyPage()),
        );
        break;
      case 'Terms of Service':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TermsOfServicePage()),
        );
        break;
      case 'Data & Privacy Settings':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const DataPrivacySettingsPage(),
          ),
        );
        break;
      default:
        // Handle any other link settings that might be added in the future
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title page is not yet implemented'),
            duration: const Duration(seconds: 2),
          ),
        );
        break;
    }
  }

  Widget _buildSectionCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: children),
    );
  }

  Widget _buildAccessibilitySection() {
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final highContrastMode = accessibilityProvider.highContrastMode;
    final fontFamilyDescription = AppLocalizations.of(
      context,
    ).translate('chooseFontFamilyDescription');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('accessibility', Icons.settings_accessibility),
        _buildSectionCard([
          _buildFontFamilySelector(
            'fontFamily',
            accessibilityProvider.fontFamily,
            fontFamilyDescription,
            icon: Icons.font_download_outlined,
          ),
        ]),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            AppLocalizations.of(context).translate('fontSizeFollowsSystem'),
            style: TextStyle(
              fontSize: 13,
              color:
                  highContrastMode
                      ? AccessibilityUtils.getAccessibleColor(
                        context,
                        isDarkMode ? Colors.white70 : Colors.black87,
                      )
                      : (isDarkMode ? Colors.white70 : Colors.black54),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFontFamilySelector(
    String title,
    String value,
    String description, {
    IconData? icon,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final highContrastMode = accessibilityProvider.highContrastMode;

    return GestureDetector(
      onTap: () {
        _showFontFamilySelectionDialog();
      },
      child: _buildSettingItem(
        title: title,
        description: description,
        leadingIcon: icon,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color:
                highContrastMode
                    ? AccessibilityUtils.getAccessibleSurfaceColor(context)
                    : (isDarkMode ? const Color(0xFF111827) : Colors.white),
            borderRadius: BorderRadius.circular(8),
            border:
                highContrastMode
                    ? Border.all(
                      color: AccessibilityUtils.getAccessibleBorderColor(
                        context,
                      ),
                      width: 2.0,
                    )
                    : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color:
                      highContrastMode
                          ? AccessibilityUtils.getAccessibleColor(
                            context,
                            isDarkMode ? Colors.white70 : Colors.black87,
                          )
                          : (isDarkMode ? Colors.white70 : Colors.black87),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_drop_down,
                color:
                    highContrastMode
                        ? AccessibilityUtils.getAccessibleColor(
                          context,
                          isDarkMode ? Colors.white54 : Colors.black54,
                        )
                        : (isDarkMode ? Colors.white54 : Colors.black54),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle _getPreviewTextStyle(
    String fontFamily,
    bool isDarkMode,
    bool isSelected,
  ) {
    final fontName = fontFamily.split(' ')[0].toLowerCase();
    const defaultFontSize = 16.0; // Ensure we always have a fontSize

    try {
      switch (fontName) {
        case 'roboto':
          return GoogleFonts.roboto(
            fontSize: defaultFontSize,
            color: isDarkMode ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          );
        case 'open':
          return GoogleFonts.openSans(
            fontSize: defaultFontSize,
            color: isDarkMode ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          );
        case 'montserrat':
          return GoogleFonts.montserrat(
            fontSize: defaultFontSize,
            color: isDarkMode ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          );
        case 'lato':
          return GoogleFonts.lato(
            fontSize: defaultFontSize,
            color: isDarkMode ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          );
        case 'inter':
        default:
          return GoogleFonts.inter(
            fontSize: defaultFontSize,
            color: isDarkMode ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          );
      }
    } catch (e) {
      debugPrint('Error loading preview font $fontFamily: $e');
      return TextStyle(
        fontSize: defaultFontSize,
        color: isDarkMode ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      );
    }
  }

  void _showFontFamilySelectionDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final accessibilityProvider = Provider.of<AccessibilityProvider>(
      context,
      listen: false,
    );
    final isDarkMode = themeProvider.isDarkMode;
    final highContrastMode = accessibilityProvider.highContrastMode;
    final accentColor =
        isDarkMode ? const Color(0xFF8A4FFF) : const Color(0xFFE53935);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor:
              highContrastMode
                  ? AccessibilityUtils.getAccessibleSurfaceColor(context)
                  : (isDarkMode ? const Color(0xFF1E293B) : Colors.white),
          shape:
              highContrastMode
                  ? RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: AccessibilityUtils.getAccessibleBorderColor(
                        context,
                      ),
                      width: 3.0,
                    ),
                  )
                  : null,
          title: LocalizedText(
            'selectFontFamily',
            style: AccessibilityUtils.getTextStyle(
              context,
              fontWeight: FontWeight.bold,
              color:
                  highContrastMode
                      ? AccessibilityUtils.getAccessibleColor(
                        context,
                        isDarkMode ? Colors.white : Colors.black87,
                      )
                      : (isDarkMode ? Colors.white : Colors.black87),
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...accessibilityProvider.fontFamilies.map((fontFamily) {
                  final isSelected =
                      accessibilityProvider.fontFamily == fontFamily;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    tileColor:
                        isSelected
                            ? accentColor.withOpacity(0.1)
                            : Colors.transparent,
                    leading:
                        isSelected
                            ? Icon(Icons.check_circle, color: accentColor)
                            : Icon(
                              Icons.font_download,
                              color:
                                  isDarkMode ? Colors.white54 : Colors.black54,
                            ),
                    title: Text(
                      fontFamily,
                      style: _getPreviewTextStyle(
                        fontFamily,
                        isDarkMode,
                        isSelected,
                      ),
                    ),
                    onTap: () {
                      accessibilityProvider.setFontFamily(fontFamily);
                      Navigator.of(context).pop();
                    },
                  );
                }),
              ],
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
          ],
        );
      },
    );
  }

  Widget _buildLanguageAudioSection() {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final languageDescription = AppLocalizations.of(
      context,
    ).translate('chooseLanguageDescription');
    final currentLanguage = languageProvider.currentLanguage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('languageAudio', Icons.language),
        _buildSectionCard([
          _buildLanguageSelector(
            'language',
            currentLanguage,
            languageDescription,
            icon: Icons.translate,
          ),
        ]),
      ],
    );
  }

  Widget _buildLanguageSelector(
    String title,
    String value,
    String description, {
    IconData? icon,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final highContrastMode = accessibilityProvider.highContrastMode;

    return GestureDetector(
      onTap: () {
        _showLanguageSelectionDialog();
      },
      child: _buildSettingItem(
        title: title,
        description: description,
        leadingIcon: icon,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color:
                highContrastMode
                    ? AccessibilityUtils.getAccessibleSurfaceColor(context)
                    : (isDarkMode ? const Color(0xFF111827) : Colors.white),
            borderRadius: BorderRadius.circular(8),
            border:
                highContrastMode
                    ? Border.all(
                      color: AccessibilityUtils.getAccessibleBorderColor(
                        context,
                      ),
                      width: 2.0,
                    )
                    : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color:
                      highContrastMode
                          ? AccessibilityUtils.getAccessibleColor(
                            context,
                            isDarkMode ? Colors.white70 : Colors.black87,
                          )
                          : (isDarkMode ? Colors.white70 : Colors.black87),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_drop_down,
                color:
                    highContrastMode
                        ? AccessibilityUtils.getAccessibleColor(
                          context,
                          isDarkMode ? Colors.white54 : Colors.black54,
                        )
                        : (isDarkMode ? Colors.white54 : Colors.black54),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageSelectionDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    final isDarkMode = themeProvider.isDarkMode;
    final accentColor =
        isDarkMode ? const Color(0xFF8A4FFF) : const Color(0xFFE53935);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          title: LocalizedText(
            'selectLanguage',
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...languageProvider.languages.map((language) {
                  final isSelected =
                      languageProvider.currentLanguage == language;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    tileColor:
                        isSelected
                            ? accentColor.withOpacity(0.1)
                            : Colors.transparent,
                    leading:
                        isSelected
                            ? Icon(Icons.check_circle, color: accentColor)
                            : Icon(
                              Icons.language,
                              color:
                                  isDarkMode ? Colors.white54 : Colors.black54,
                            ),
                    title: Text(
                      language,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black87,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    onTap: () {
                      languageProvider.setLanguage(language);
                      Navigator.of(context).pop();
                    },
                  );
                }),
              ],
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
          ],
        );
      },
    );
  }

  Widget _buildDataPerformanceSection() {
    final dataPerformanceProvider = Provider.of<DataPerformanceProvider>(
      context,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('dataPerformance', Icons.data_usage),
        _buildSectionCard([
          _buildSwitchSetting(
            'lowDataMode',
            'Reduce data usage for remote areas',
            dataPerformanceProvider.lowDataMode,
            (value) => dataPerformanceProvider.toggleLowDataMode(value),
            icon: Icons.data_saver_off,
          ),
          _buildSwitchSetting(
            'imageLazyLoading',
            'Load images only when needed',
            dataPerformanceProvider.imageLazyLoading,
            (value) => dataPerformanceProvider.toggleImageLazyLoading(value),
            icon: Icons.image,
          ),
          _buildSwitchSetting(
            'offlineMode',
            'Cache content for offline access',
            dataPerformanceProvider.offlineMode,
            (value) => dataPerformanceProvider.toggleOfflineMode(value),
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
        _buildSectionHeader('appearance', Icons.palette_outlined),
        _buildSectionCard([
          _buildSwitchSetting(
            'darkMode',
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
    final notificationProvider = Provider.of<NotificationProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('notifications', Icons.notifications_outlined),
        _buildSectionCard([
          _buildSwitchSetting(
            'forumReplies',
            'Get notified of new replies',
            notificationProvider.forumReplies,
            (value) => notificationProvider.toggleForumReplies(value),
            icon: Icons.chat_bubble_outline,
          ),
          _buildSwitchSetting(
            'weeklyCheckIns',
            'Mental health reminders',
            notificationProvider.weeklyCheckIns,
            (value) => notificationProvider.toggleWeeklyCheckIns(value),
            icon: Icons.event_note,
          ),
          _buildSwitchSetting(
            'systemUpdates',
            'App updates and news',
            notificationProvider.systemUpdates,
            (value) => notificationProvider.toggleSystemUpdates(value),
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
        _buildSectionHeader('privacySecurity', Icons.shield_outlined),
        _buildSectionCard([
          _buildLinkSetting('Privacy Policy', icon: Icons.privacy_tip),
          _buildLinkSetting('Terms of Service', icon: Icons.description),
          _buildLinkSetting(
            'Data & Privacy Settings',
            icon: Icons.settings_applications,
          ),
          if (isLoggedIn) _buildLogoutButton(),
        ]),
      ],
    );
  }

  Widget _buildDatabaseSection() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final highContrastMode = accessibilityProvider.highContrastMode;
    final accentColor =
        isDarkMode ? const Color(0xFF8A4FFF) : const Color(0xFFE53935);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('database', Icons.storage_outlined),
        _buildSectionCard([
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FirebaseImportPage(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color:
                    highContrastMode
                        ? AccessibilityUtils.getAccessibleSurfaceColor(context)
                        : (isDarkMode
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      highContrastMode
                          ? AccessibilityUtils.getAccessibleBorderColor(context)
                          : accentColor.withOpacity(0.5),
                  width: highContrastMode ? 2.0 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    color:
                        highContrastMode
                            ? AccessibilityUtils.getAccessibleColor(
                              context,
                              accentColor,
                              isPrimary: true,
                            )
                            : accentColor,
                    size: 20,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Import to Firebase',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color:
                                highContrastMode
                                    ? AccessibilityUtils.getAccessibleColor(
                                      context,
                                      isDarkMode
                                          ? Colors.white
                                          : Colors.black87,
                                    )
                                    : (isDarkMode
                                        ? Colors.white
                                        : Colors.black87),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Import user data to Firebase database',
                            style: TextStyle(
                              fontSize: 13,
                              color:
                                  highContrastMode
                                      ? AccessibilityUtils.getAccessibleColor(
                                        context,
                                        isDarkMode
                                            ? Colors.white60
                                            : Colors.black54,
                                      )
                                      : (isDarkMode
                                          ? Colors.white60
                                          : Colors.black54),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color:
                        highContrastMode
                            ? AccessibilityUtils.getAccessibleColor(
                              context,
                              isDarkMode ? Colors.white54 : Colors.black54,
                            )
                            : (isDarkMode ? Colors.white54 : Colors.black54),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
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
          border: Border.all(color: Colors.red.withOpacity(0.5), width: 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.logout, color: Colors.red, size: 20),
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
            const Icon(Icons.arrow_forward_ios, color: Colors.red, size: 16),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmation() {
    final authService = Provider.of<AuthService>(context, listen: false);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
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
                child: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildEmergencyContactsSection() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final highContrastMode = accessibilityProvider.highContrastMode;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient:
            highContrastMode
                ? null // No gradients in high contrast mode
                : const LinearGradient(
                  colors: [Color(0xFF6B1D1D), Color(0xFF8B2121)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
        color:
            highContrastMode
                ? (isDarkMode ? Colors.black : Colors.white)
                : null,
        borderRadius: BorderRadius.circular(16),
        border:
            highContrastMode
                ? Border.all(
                  color: isDarkMode ? Colors.white : Colors.black,
                  width: 2.0,
                )
                : null,
        boxShadow:
            highContrastMode
                ? null // No shadows in high contrast mode
                : [
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
            children: [
              Icon(
                Icons.emergency,
                color:
                    highContrastMode
                        ? (isDarkMode ? Colors.white : Colors.black)
                        : Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Emergency Contacts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color:
                      highContrastMode
                          ? (isDarkMode ? Colors.white : Colors.black)
                          : Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color:
                  highContrastMode
                      ? (isDarkMode
                          ? Colors.white.withOpacity(0.2)
                          : Colors.black.withOpacity(0.2))
                      : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Tap on any contact to make an emergency call',
              style: TextStyle(
                color:
                    highContrastMode
                        ? (isDarkMode
                            ? Colors.white.withOpacity(0.9)
                            : Colors.black.withOpacity(0.9))
                        : Colors.white.withOpacity(0.9),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildEmergencyContact('Isange One Stop Center', '3029'),
          const SizedBox(height: 8),
          _buildEmergencyContact('Rwanda National Police', '3512'),
          const SizedBox(height: 8),
          _buildEmergencyContact('HopeCore Team', '+250780332779'),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _showEmergencySOSDialog(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color:
                    highContrastMode
                        ? (isDarkMode ? Colors.white : Colors.black)
                        : Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow:
                    highContrastMode
                        ? null
                        : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.emergency_outlined,
                    color:
                        highContrastMode
                            ? (isDarkMode ? Colors.black : Colors.white)
                            : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'SOS EMERGENCY CALL',
                    style: TextStyle(
                      color:
                          highContrastMode
                              ? (isDarkMode ? Colors.black : Colors.white)
                              : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Add a dialog for SOS emergency call
  void _showEmergencySOSDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          title: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                'Emergency SOS',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to make an emergency call?',
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Select an emergency service to call:',
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              _buildEmergencyCallOption(
                context,
                'Police Emergency',
                '112',
                isDarkMode,
              ),
              const SizedBox(height: 8),
              _buildEmergencyCallOption(
                context,
                'Isange One Stop Center',
                '3029',
                isDarkMode,
              ),
              const SizedBox(height: 8),
              _buildEmergencyCallOption(
                context,
                'HopeCore Support',
                '+250780332779',
                isDarkMode,
              ),
            ],
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
          ],
        );
      },
    );
  }

  // Build an emergency call option button
  Widget _buildEmergencyCallOption(
    BuildContext context,
    String name,
    String number,
    bool isDarkMode,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        _makePhoneCall(number);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(isDarkMode ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  number,
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.call, color: Colors.white, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyContact(String label, String number) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final highContrastMode = accessibilityProvider.highContrastMode;

    return GestureDetector(
      onTap: () => _makePhoneCall(number),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              highContrastMode
                  ? (isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.1))
                  : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                highContrastMode
                    ? (isDarkMode
                        ? Colors.white.withOpacity(0.2)
                        : Colors.black.withOpacity(0.2))
                    : Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color:
                    highContrastMode
                        ? (isDarkMode ? Colors.white70 : Colors.black87)
                        : Colors.white70,
              ),
            ),
            Row(
              children: [
                Text(
                  number,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color:
                        highContrastMode
                            ? (isDarkMode ? Colors.white : Colors.black)
                            : Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color:
                        highContrastMode
                            ? (isDarkMode
                                ? Colors.white.withOpacity(0.2)
                                : Colors.black.withOpacity(0.2))
                            : Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.call,
                    color:
                        highContrastMode
                            ? (isDarkMode ? Colors.white : Colors.black)
                            : Colors.white,
                    size: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
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
          Image.asset('assets/logo.png', width: 40, height: 40),
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
              color: (isDarkMode ? Colors.white : Colors.black).withOpacity(
                0.5,
              ),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContentPolicySection() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final accentColor =
        isDarkMode ? const Color(0xFF8A4FFF) : const Color(0xFFE53935);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('contentPolicyReporting', Icons.policy),
        _buildSectionCard([
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'AI-Generated Content Policy',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'This app contains AI-generated content from our Mahoro AI companion. You can report any content that violates our community guidelines by using the flag button (🏴) available on AI messages and forum posts.',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Report Categories:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                ...[
                  '• Inappropriate content',
                  '• Harmful or dangerous information',
                  '• Spam or unwanted content',
                  '• Misinformation',
                  '• Harassment or bullying',
                  '• Other concerns',
                ].map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDarkMode ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.security, color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'All reports are reviewed by our moderation team within 24 hours.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ]),
      ],
    );
  }

  Widget _buildAdminSection() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final accentColor =
        isDarkMode ? const Color(0xFF8A4FFF) : const Color(0xFFE53935);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('adminControls', Icons.admin_panel_settings),
        _buildSectionCard([
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminPage()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color:
                    isDarkMode
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: accentColor.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.dashboard, color: accentColor, size: 20),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin Dashboard',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Manage subscriptions and user data',
                            style: TextStyle(
                              fontSize: 13,
                              color:
                                  isDarkMode ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: isDarkMode ? Colors.white54 : Colors.black54,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ]),
      ],
    );
  }
}
