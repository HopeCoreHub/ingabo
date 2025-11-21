import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
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
          'Privacy Policy',
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
            _buildLastUpdated(isDarkMode),
            const SizedBox(height: 24),
            _buildHighlightCards(isDarkMode),
            const SizedBox(height: 24),
            _buildSection(
              'Information We Collect',
              [
                'Name and contact information (email, phone number)',
                'Demographic information (age, location, if voluntarily provided)',
                'Communication preferences and language settings',
              ],
              isDarkMode,
              subtitle: 'Personal Information',
            ),
            _buildSection('Service Usage Data', [
              'App usage patterns and feature interactions',
              'Support request history and communication records',
              'Emergency contact information (when provided)',
            ], isDarkMode),
            _buildSection('Technical Information', [
              'Device information and operating system',
              'IP address and general location data',
              'App performance and error logs',
            ], isDarkMode),
            _buildSection('How We Use Your Information', [
              'Provide personalized support and mental health resources',
              'Respond to your inquiries and support requests',
              'Send important safety alerts and service updates',
              'Improve our services through anonymous analytics',
              'Ensure platform security and prevent misuse',
              'Comply with legal obligations and emergency situations',
            ], isDarkMode),
            _buildSection('Data Protection & Security', [
              'All personal data is encrypted both in transit and at rest using industry-standard encryption protocols',
              'Our systems are regularly audited for security vulnerabilities',
              'Only authorized personnel with legitimate need have access to personal data',
              'All access is logged and monitored for compliance',
              'We retain personal data only as long as necessary to provide services or as required by law',
            ], isDarkMode),
            _buildSection(
              'Data Sharing & Third Parties',
              [
                'We never sell, rent, or trade your personal information to third parties for marketing purposes',
                'Emergency situations where immediate safety is at risk',
                'Legal compliance when required by law enforcement or courts',
                'Service providers who help us operate the platform (under strict confidentiality agreements)',
                'Anonymous, aggregated data for research and advocacy (no personal identification)',
              ],
              isDarkMode,
              subtitle: 'We Do Not Sell Your Data',
            ),
            _buildSection('Your Rights & Choices', [
              'Access: Request a copy of your personal data',
              'Correction: Update or correct inaccurate information',
              'Deletion: Request deletion of your account and data',
              'Portability: Request your data in a portable format',
              'Consent Withdrawal: Withdraw consent for non-essential processing',
              'Communication Preferences: Opt out of non-critical communications',
            ], isDarkMode),
            const SizedBox(height: 32),
            _buildContactInfo(isDarkMode),
            const SizedBox(height: 24),
            _buildFooter(isDarkMode),
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
          color: isDarkMode ? Colors.white12 : Colors.black.withAlpha(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shield_outlined,
                color: const Color(0xFF7C3AED),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Your Privacy Matters',
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
            'At Ingabo HopeCore, we are committed to protecting your privacy and personal data. This policy explains how we collect, use, and safeguard your information.',
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

  Widget _buildLastUpdated(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF312E81) : const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Last updated: January 2025',
        style: TextStyle(
          fontSize: 12,
          color: isDarkMode ? Colors.white70 : const Color(0xFF4338CA),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSection(
    String title,
    List<String> content,
    bool isDarkMode, {
    String? subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF7C3AED),
            ),
          ),
        ],
        const SizedBox(height: 12),
        ...content.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8, right: 12),
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHighlightCards(bool isDarkMode) {
    final highlights = [
      {
        'title': 'Data Protection',
        'subtitle': 'Your data is encrypted and secure',
        'icon': Icons.security,
      },
      {
        'title': 'Confidentiality',
        'subtitle': 'Strict confidentiality protocols',
        'icon': Icons.lock,
      },
      {
        'title': 'Transparency',
        'subtitle': 'Clear about what we collect',
        'icon': Icons.visibility,
      },
      {
        'title': 'Your Control',
        'subtitle': 'You control your data',
        'icon': Icons.settings,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: highlights.length,
      itemBuilder: (context, index) {
        final highlight = highlights[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDarkMode ? Colors.white12 : Colors.black.withAlpha(12),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                highlight['icon'] as IconData,
                color: const Color(0xFF7C3AED),
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                highlight['title'] as String,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                highlight['subtitle'] as String,
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.white54 : Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContactInfo(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.white12 : Colors.black.withAlpha(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.contact_support_outlined,
                color: const Color(0xFF7C3AED),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Contact Us',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'To exercise any of your rights or if you have questions about this Privacy Policy, please contact us:',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Privacy Officer: privacy@ingabohopecore.com\nPhone: +250 784 503 884\nWebsite: www.ingabohopecore.com',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white70 : Colors.black54,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isDarkMode) {
    return Center(
      child: Text(
        'This privacy policy may be updated periodically. We will notify users of significant changes through our app and website. Continued use of our services after updates constitutes acceptance of the revised policy.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          color: isDarkMode ? Colors.white54 : Colors.black45,
          height: 1.4,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
