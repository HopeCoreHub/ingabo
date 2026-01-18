import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import '../models/post_model.dart';
import '../services/auth_service.dart';
import '../localization/localized_text.dart';

class ReplyDialog extends StatefulWidget {
  final Post post;
  final Function(String) onReply;

  const ReplyDialog({super.key, required this.post, required this.onReply});

  @override
  State<ReplyDialog> createState() => _ReplyDialogState();
}

class _ReplyDialogState extends State<ReplyDialog> {
  final TextEditingController _replyController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authService = Provider.of<AuthService>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final accentColor =
        isDarkMode ? const Color(0xFF8A4FFF) : const Color(0xFFE53935);

    // Get first letter of username for avatar
    final String firstLetter = (authService.username ?? 'A')[0].toUpperCase();
    final bool isGuest = authService.isGuest;

    return Dialog(
      backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reply to Post',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.post.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            // User info row
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor,
                  ),
                  child: Center(
                    child: Text(
                      firstLetter,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Replying as ${authService.username}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
                if (isGuest) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: isDarkMode ? Colors.white54 : Colors.black45,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _replyController,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
              maxLines: 5,
              minLines: 3,
              decoration: InputDecoration(
                hintText: 'Write your reply...',
                hintStyle: TextStyle(
                  color: isDarkMode ? Colors.white54 : Colors.black54,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDarkMode ? Colors.white30 : Colors.black12,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: accentColor),
                ),
                filled: true,
                fillColor: isDarkMode ? Colors.black : const Color(0xFFF1F5F9),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor:
                        isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                  child: LocalizedText('cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: accentColor.withAlpha(127),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child:
                      _isSubmitting
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : LocalizedText('submit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submitReply() {
    final replyText = _replyController.text.trim();
    if (replyText.isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    final navigator = Navigator.of(context);
    // Simulate network delay
    Future.delayed(const Duration(milliseconds: 500), () {
      widget.onReply(replyText);
      if (mounted) {
        navigator.pop();
      }
    });
  }
}
