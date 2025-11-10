import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme_provider.dart';
import '../accessibility_provider.dart';
import '../localization/localized_text.dart';

class AiContentPolicyNotice extends StatelessWidget {
  static const String _policyNoticeShownKey = 'ai_content_policy_notice_shown';

  const AiContentPolicyNotice({super.key});

  /// Check if the policy notice has been shown before
  static Future<bool> hasBeenShown() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_policyNoticeShownKey) ?? false;
  }

  /// Mark the policy notice as shown
  static Future<void> markAsShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_policyNoticeShownKey, true);
  }

  /// Show the policy notice dialog if it hasn't been shown before
  static Future<void> showIfNeeded(BuildContext context) async {
    final hasShown = await hasBeenShown();
    if (!hasShown && context.mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AiContentPolicyNotice(),
      );
      await markAsShown();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final highContrastMode = accessibilityProvider.highContrastMode;

    return AlertDialog(
      backgroundColor:
          highContrastMode
              ? (isDarkMode ? Colors.black : Colors.white)
              : (isDarkMode ? const Color(0xFF1E293B) : Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side:
            highContrastMode
                ? BorderSide(
                  color: isDarkMode ? Colors.white : Colors.black,
                  width: 2,
                )
                : BorderSide.none,
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.policy, color: Colors.blue, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'AI Content Policy',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withAlpha(51)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.smart_toy, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'AI-Generated Content Notice',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'This app includes AI-generated content from our Mahoro AI companion, powered by Claude AI. The AI provides mental health support and guidance.',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withAlpha(51)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.flag, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Content Reporting',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'You can report any AI-generated content or user posts that violate our community guidelines. Look for the flag icon (🏴) on messages and posts.',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
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
                                fontWeight: FontWeight.w500,
                                color:
                                    isDarkMode
                                        ? Colors.white70
                                        : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This notice will only be shown once. You can find more information in Settings > Content Policy & Reporting.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.white54 : Colors.black54,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: LocalizedText('iUnderstand'),
        ),
      ],
    );
  }
}
