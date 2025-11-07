import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import '../services/auth_service.dart';

class DataPrivacySettingsPage extends StatefulWidget {
  const DataPrivacySettingsPage({super.key});

  @override
  State<DataPrivacySettingsPage> createState() =>
      _DataPrivacySettingsPageState();
}

class _DataPrivacySettingsPageState extends State<DataPrivacySettingsPage> {
  bool _analyticsEnabled = true;
  bool _crashReportingEnabled = true;
  bool _personalizedContentEnabled = true;
  bool _dataExportRequested = false;
  bool _accountDeletionRequested = false;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authService = Provider.of<AuthService>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Data & Privacy Settings',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isDarkMode),
            const SizedBox(height: 32),
            _buildDataCollectionSection(isDarkMode),
            const SizedBox(height: 24),
            _buildDataRightsSection(isDarkMode, authService),
            const SizedBox(height: 24),
            _buildSecuritySection(isDarkMode),
            const SizedBox(height: 24),
            _buildDangerZoneSection(isDarkMode, authService),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.white12 : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.settings_applications,
                color: const Color(0xFF7C3AED),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Privacy Controls',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Manage how your data is collected, used, and shared. You have full control over your privacy settings and can modify them at any time.',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white70 : Colors.black54,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataCollectionSection(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Data Collection Preferences',
          Icons.data_usage,
          isDarkMode,
        ),
        const SizedBox(height: 16),
        _buildSettingCard([
          _buildToggleSetting(
            'Usage Analytics',
            'Help improve our app by sharing anonymous usage data',
            _analyticsEnabled,
            (value) => setState(() => _analyticsEnabled = value),
            Icons.analytics_outlined,
            isDarkMode,
          ),
          _buildToggleSetting(
            'Crash Reporting',
            'Automatically send crash reports to help us fix issues',
            _crashReportingEnabled,
            (value) => setState(() => _crashReportingEnabled = value),
            Icons.bug_report_outlined,
            isDarkMode,
          ),
          _buildToggleSetting(
            'Personalized Content',
            'Use your data to personalize your experience and recommendations',
            _personalizedContentEnabled,
            (value) => setState(() => _personalizedContentEnabled = value),
            Icons.person_outline,
            isDarkMode,
          ),
        ], isDarkMode),
      ],
    );
  }

  Widget _buildDataRightsSection(bool isDarkMode, AuthService authService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Your Data Rights',
          Icons.account_balance,
          isDarkMode,
        ),
        const SizedBox(height: 16),
        _buildSettingCard([
          _buildActionSetting(
            'View My Data',
            'See all the data we have collected about you',
            Icons.visibility_outlined,
            () => _showDataPreview(isDarkMode),
            isDarkMode,
          ),
          _buildActionSetting(
            'Export My Data',
            _dataExportRequested
                ? 'Export requested - check your email'
                : 'Download a copy of all your data',
            Icons.download_outlined,
            _dataExportRequested ? null : () => _requestDataExport(),
            isDarkMode,
            isDisabled: _dataExportRequested,
          ),
          _buildActionSetting(
            'Data Correction',
            'Request corrections to your personal information',
            Icons.edit_outlined,
            () => _showDataCorrectionDialog(isDarkMode),
            isDarkMode,
          ),
        ], isDarkMode),
      ],
    );
  }

  Widget _buildSecuritySection(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Security & Access', Icons.security, isDarkMode),
        const SizedBox(height: 16),
        _buildSettingCard([
          _buildActionSetting(
            'Active Sessions',
            'Manage devices that have access to your account',
            Icons.devices_outlined,
            () => _showActiveSessionsDialog(isDarkMode),
            isDarkMode,
          ),
          _buildActionSetting(
            'Login History',
            'View recent login activity and locations',
            Icons.history_outlined,
            () => _showLoginHistoryDialog(isDarkMode),
            isDarkMode,
          ),
          _buildActionSetting(
            'Change Password',
            'Update your account password',
            Icons.lock_outline,
            () => _showChangePasswordDialog(isDarkMode),
            isDarkMode,
          ),
        ], isDarkMode),
      ],
    );
  }

  Widget _buildDangerZoneSection(bool isDarkMode, AuthService authService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Danger Zone',
          Icons.warning_outlined,
          isDarkMode,
          isWarning: true,
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color:
                isDarkMode ? const Color(0xFF7F1D1D) : const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isDarkMode
                      ? const Color(0xFFDC2626)
                      : const Color(0xFFFCA5A5),
            ),
          ),
          child: Column(
            children: [
              _buildActionSetting(
                'Delete All My Data',
                _accountDeletionRequested
                    ? 'Deletion requested - contact support to cancel'
                    : 'Permanently delete your account and all associated data',
                Icons.delete_forever_outlined,
                _accountDeletionRequested
                    ? null
                    : () => _showDeleteAccountDialog(isDarkMode, authService),
                isDarkMode,
                isDestructive: true,
                isDisabled: _accountDeletionRequested,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    String title,
    IconData icon,
    bool isDarkMode, {
    bool isWarning = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color:
              isWarning
                  ? (isDarkMode
                      ? const Color(0xFFFCA5A5)
                      : const Color(0xFFDC2626))
                  : const Color(0xFF7C3AED),
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color:
                isWarning
                    ? (isDarkMode
                        ? const Color(0xFFFCA5A5)
                        : const Color(0xFFDC2626))
                    : (isDarkMode ? Colors.white : Colors.black),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingCard(List<Widget> children, bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.white12 : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildToggleSetting(
    String title,
    String description,
    bool value,
    Function(bool) onChanged,
    IconData icon,
    bool isDarkMode,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDarkMode ? Colors.white12 : Colors.black.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isDarkMode ? Colors.white54 : Colors.black54,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.white54 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF7C3AED),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSetting(
    String title,
    String description,
    IconData icon,
    VoidCallback? onTap,
    bool isDarkMode, {
    bool isDestructive = false,
    bool isDisabled = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDarkMode ? Colors.white12 : Colors.black.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color:
              isDisabled
                  ? (isDarkMode ? Colors.white24 : Colors.black26)
                  : isDestructive
                  ? (isDarkMode
                      ? const Color(0xFFFCA5A5)
                      : const Color(0xFFDC2626))
                  : (isDarkMode ? Colors.white54 : Colors.black54),
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color:
                isDisabled
                    ? (isDarkMode ? Colors.white24 : Colors.black26)
                    : isDestructive
                    ? (isDarkMode
                        ? const Color(0xFFFCA5A5)
                        : const Color(0xFFDC2626))
                    : (isDarkMode ? Colors.white : Colors.black),
          ),
        ),
        subtitle: Text(
          description,
          style: TextStyle(
            fontSize: 12,
            color:
                isDisabled
                    ? (isDarkMode ? Colors.white24 : Colors.black26)
                    : (isDarkMode ? Colors.white54 : Colors.black54),
          ),
        ),
        trailing:
            isDisabled
                ? null
                : Icon(
                  Icons.arrow_forward_ios,
                  color: isDarkMode ? Colors.white54 : Colors.black54,
                  size: 16,
                ),
        onTap: isDisabled ? null : onTap,
      ),
    );
  }

  void _showDataPreview(bool isDarkMode) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor:
                isDarkMode ? const Color(0xFF1E293B) : Colors.white,
            title: Text(
              'Your Data Overview',
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDataItem('Profile Information', '1 record', isDarkMode),
                  _buildDataItem('Journal Entries', '23 records', isDarkMode),
                  _buildDataItem('Mood Check-ins', '45 records', isDarkMode),
                  _buildDataItem('Forum Posts', '12 records', isDarkMode),
                  _buildDataItem(
                    'Settings & Preferences',
                    '8 records',
                    isDarkMode,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Close',
                  style: TextStyle(color: const Color(0xFF7C3AED)),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildDataItem(String type, String count, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            type,
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
          Text(
            count,
            style: TextStyle(
              color: isDarkMode ? Colors.white54 : Colors.black54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _requestDataExport() {
    setState(() => _dataExportRequested = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Data export requested. You will receive an email with download instructions within 24 hours.',
        ),
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _showDataCorrectionDialog(bool isDarkMode) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor:
                isDarkMode ? const Color(0xFF1E293B) : Colors.white,
            title: Text(
              'Request Data Correction',
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            ),
            content: Text(
              'To request corrections to your personal information, please contact our support team with details about what needs to be corrected.',
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white54 : Colors.black54,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // TODO: Implement contact support functionality
                },
                child: Text(
                  'Contact Support',
                  style: TextStyle(color: const Color(0xFF7C3AED)),
                ),
              ),
            ],
          ),
    );
  }

  void _showActiveSessionsDialog(bool isDarkMode) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor:
                isDarkMode ? const Color(0xFF1E293B) : Colors.white,
            title: Text(
              'Active Sessions',
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSessionItem('Current Device', 'Now', true, isDarkMode),
                _buildSessionItem(
                  'iPhone 12',
                  '2 hours ago',
                  false,
                  isDarkMode,
                ),
                _buildSessionItem(
                  'Chrome Browser',
                  '1 day ago',
                  false,
                  isDarkMode,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Close',
                  style: TextStyle(color: const Color(0xFF7C3AED)),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildSessionItem(
    String device,
    String lastActive,
    bool isCurrent,
    bool isDarkMode,
  ) {
    return ListTile(
      leading: Icon(
        isCurrent ? Icons.smartphone : Icons.devices,
        color: isDarkMode ? Colors.white54 : Colors.black54,
      ),
      title: Text(
        device,
        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
      ),
      subtitle: Text(
        lastActive,
        style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54),
      ),
      trailing:
          isCurrent
              ? Text(
                'Current',
                style: TextStyle(color: const Color(0xFF7C3AED), fontSize: 12),
              )
              : TextButton(
                onPressed: () {
                  // TODO: Implement session termination
                },
                child: Text('Revoke', style: TextStyle(color: Colors.red)),
              ),
    );
  }

  void _showLoginHistoryDialog(bool isDarkMode) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor:
                isDarkMode ? const Color(0xFF1E293B) : Colors.white,
            title: Text(
              'Login History',
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLoginItem('Now', 'Current location', true, isDarkMode),
                  _buildLoginItem(
                    '2 hours ago',
                    'Same location',
                    false,
                    isDarkMode,
                  ),
                  _buildLoginItem(
                    'Yesterday 3:45 PM',
                    'Home network',
                    false,
                    isDarkMode,
                  ),
                  _buildLoginItem(
                    '2 days ago 9:22 AM',
                    'Mobile network',
                    false,
                    isDarkMode,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Close',
                  style: TextStyle(color: const Color(0xFF7C3AED)),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildLoginItem(
    String time,
    String location,
    bool isCurrent,
    bool isDarkMode,
  ) {
    return ListTile(
      leading: Icon(
        Icons.login,
        color:
            isCurrent
                ? const Color(0xFF7C3AED)
                : (isDarkMode ? Colors.white54 : Colors.black54),
      ),
      title: Text(
        time,
        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
      ),
      subtitle: Text(
        location,
        style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54),
      ),
    );
  }

  void _showChangePasswordDialog(bool isDarkMode) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor:
                isDarkMode ? const Color(0xFF1E293B) : Colors.white,
            title: Text(
              'Change Password',
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            ),
            content: Text(
              'For security reasons, password changes must be done through the main account settings. Would you like to navigate there now?',
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white54 : Colors.black54,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // TODO: Navigate to password change page
                },
                child: Text(
                  'Go to Settings',
                  style: TextStyle(color: const Color(0xFF7C3AED)),
                ),
              ),
            ],
          ),
    );
  }

  void _showDeleteAccountDialog(bool isDarkMode, AuthService authService) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor:
                isDarkMode ? const Color(0xFF1E293B) : Colors.white,
            title: Text(
              'Delete Account',
              style: TextStyle(
                color:
                    isDarkMode
                        ? const Color(0xFFFCA5A5)
                        : const Color(0xFFDC2626),
              ),
            ),
            content: Text(
              'This action cannot be undone. All your data including journal entries, mood tracking, and forum posts will be permanently deleted.\n\nAre you sure you want to proceed?',
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white54 : Colors.black54,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() => _accountDeletionRequested = true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Account deletion requested. Our team will contact you within 24 hours to confirm.',
                      ),
                      duration: Duration(seconds: 4),
                    ),
                  );
                },
                child: Text(
                  'Delete Account',
                  style: TextStyle(
                    color:
                        isDarkMode
                            ? const Color(0xFFFCA5A5)
                            : const Color(0xFFDC2626),
                  ),
                ),
              ),
            ],
          ),
    );
  }
}
