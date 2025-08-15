import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

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
          'Terms of Service',
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
              'Service Description',
              [
                'Crisis support and emergency response services',
                'Mental health resources and trauma-informed therapy',
                'Community support platforms and peer connections',
                'Educational content and prevention resources',
                'Mobile application with safety and support tools',
              ],
              isDarkMode,
              subtitle: 'What We Provide',
            ),
            _buildSection(
              'Service Availability',
              [
                'We strive to provide 24/7 access to our digital platforms.',
                'Services may be temporarily unavailable due to maintenance, technical issues, or circumstances beyond our control.',
              ],
              isDarkMode,
            ),
            _buildSection(
              'User Responsibilities',
              [
                'Provide accurate information when registering or using services',
                'Keep your account credentials secure and confidential',
                'Notify us immediately of any unauthorized access',
                'Update your information when it changes',
              ],
              isDarkMode,
              subtitle: 'Account & Information',
            ),
            _buildSection(
              'Appropriate Use',
              [
                'Use services for their intended purpose of safety and support',
                'Respect other users and maintain confidentiality',
                'Do not share harmful, illegal, or abusive content',
                'Do not attempt to compromise platform security',
              ],
              isDarkMode,
            ),
            _buildSection(
              'Important Disclaimers',
              [
                'If you are in immediate danger, call emergency services (112) or local police immediately.',
                'Our platform is not a substitute for emergency services and may not be monitored continuously.',
              ],
              isDarkMode,
              subtitle: 'Emergency Situations',
            ),
            _buildSection(
              'Medical & Legal Advice',
              [
                'Our services provide support and resources but do not constitute professional medical, legal, or psychiatric advice.',
                'Always consult qualified professionals for specific medical or legal guidance.',
              ],
              isDarkMode,
            ),
            _buildSection(
              'Privacy & Confidentiality',
              [
                'We are committed to protecting your privacy and maintaining confidentiality.',
                'Our privacy policy details how we collect, use, and protect your information.',
                'In certain circumstances, we may be legally required to report information to authorities.',
                'Information shared in community forums may be seen by other users.',
              ],
              isDarkMode,
            ),
            _buildSection(
              'Prohibited Activities',
              [
                'Harassment, abuse, or threatening behavior toward other users',
                'Sharing false information or impersonating others',
                'Attempting to hack, disrupt, or compromise platform security',
                'Using services for illegal activities or commercial purposes',
                'Sharing or distributing harmful, explicit, or inappropriate content',
                'Violating intellectual property rights',
                'Circumventing safety measures or reporting systems',
              ],
              isDarkMode,
            ),
            _buildSection(
              'Liability & Indemnification',
              [
                'To the maximum extent permitted by law, Ingabo HopeCore shall not be liable for any indirect, incidental, special, or consequential damages.',
                'Users agree to indemnify and hold harmless Ingabo HopeCore from any claims, damages, or expenses arising from their use of services.',
              ],
              isDarkMode,
            ),
            _buildSection(
              'Changes & Termination',
              [
                'We may update these terms periodically. Significant changes will be communicated through our platform.',
                'You may terminate your account at any time.',
                'We may suspend or terminate accounts for violation of terms or to protect user safety.',
              ],
              isDarkMode,
            ),
            _buildSection(
              'Governance',
              [
                'These terms are governed by the laws of Rwanda.',
                'Any disputes will be resolved through appropriate legal channels in Rwanda.',
              ],
              isDarkMode,
            ),
            const SizedBox(height: 32),
            _buildEmergencyNotice(isDarkMode),
            const SizedBox(height: 24),
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
          color: isDarkMode ? Colors.white12 : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description_outlined,
                color: const Color(0xFF7C3AED),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Terms of Service',
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
            'These terms govern your use of Ingabo HopeCore services. By using our platform, you agree to these terms and our commitment to supporting your safety and well-being.',
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

  Widget _buildSection(String title, List<String> content, bool isDarkMode, {String? subtitle}) {
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
        ...content.map((item) => Padding(
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
        )),
      ],
    );
  }

  Widget _buildHighlightCards(bool isDarkMode) {
    final highlights = [
      {'title': 'Safety First', 'subtitle': 'Your safety is our priority', 'icon': Icons.security},
      {'title': 'Confidentiality', 'subtitle': 'Protected communications', 'icon': Icons.lock},
      {'title': 'Community', 'subtitle': 'Respectful interactions', 'icon': Icons.people},
      {'title': 'Fair Use', 'subtitle': 'Responsible platform use', 'icon': Icons.balance},
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
            color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDarkMode ? Colors.white12 : Colors.black.withOpacity(0.05),
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

  Widget _buildEmergencyNotice(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF7F1D1D) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? const Color(0xFFDC2626) : const Color(0xFFFCA5A5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emergency,
                color: isDarkMode ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Crisis Resources',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'If you are experiencing a mental health crisis or thoughts of self-harm, please contact emergency services immediately:\n\n• Emergency Services: 911 (US) or your local emergency number\n• National Suicide Prevention Lifeline: 988\n• Crisis Text Line: Text HOME to 741741\n\nYour safety is our priority. Please seek immediate help if you are in danger.',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white70 : const Color(0xFF7F1D1D),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo(bool isDarkMode) {
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
            'If you have questions about these Terms of Service, please contact us:',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Legal Inquiries: legal@ingabohopecore.com\nGeneral Contact: +250 784 503 884\nWebsite: www.ingabohopecore.com',
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
        'These terms are designed to protect all users while supporting our mission of providing safe, effective support for survivors. Thank you for being part of our community.',
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
