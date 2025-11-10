import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import '../services/auth_service.dart';
import '../localization/app_localizations.dart';
import '../localization/localized_text.dart';

class PostCreationDialog extends StatefulWidget {
  final Function(String, String) onCreatePost;

  const PostCreationDialog({super.key, required this.onCreatePost});

  @override
  State<PostCreationDialog> createState() => _PostCreationDialogState();
}

class _PostCreationDialogState extends State<PostCreationDialog>
    with SingleTickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool _isSubmitting = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: ThemeProvider.animationDurationMedium,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: ThemeProvider.animationCurveSnappy,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: ThemeProvider.animationCurveDefault,
    );

    // Start animations when the dialog appears
    _animationController.forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _animationController.dispose();
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
    final bool isGuest = authService.username == 'Guest';

    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Dialog(
          backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDialogHeader(
                  isDarkMode,
                  firstLetter,
                  isGuest,
                  authService,
                ),
                const SizedBox(height: 24),
                _buildTitleField(isDarkMode, accentColor),
                const SizedBox(height: 16),
                _buildContentField(isDarkMode, accentColor),
                const SizedBox(height: 24),
                _buildDialogActions(isDarkMode, accentColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogHeader(
    bool isDarkMode,
    String firstLetter,
    bool isGuest,
    AuthService authService,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with title
        Row(
          children: [
            Text(
              'Create a Post',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: Icon(
                Icons.close,
                color: isDarkMode ? Colors.white54 : Colors.black45,
                size: 20,
              ),
              onPressed: () => Navigator.of(context).pop(),
              splashRadius: 20,
            ),
          ],
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
                color:
                    isDarkMode
                        ? const Color(0xFF8A4FFF)
                        : const Color(0xFFE53935),
                boxShadow: [
                  BoxShadow(
                    color:
                        isDarkMode
                            ? const Color(0xFF8A4FFF).withAlpha(76)
                            : const Color(0xFFE53935).withAlpha(76),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
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
            const SizedBox(width: 12),
            Text(
              'Posting as ${authService.username}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
            if (isGuest) ...[
              const SizedBox(width: 4),
              Tooltip(
                message:
                    'You are posting as a guest. Sign in to track your posts.',
                child: Icon(
                  Icons.info_outline,
                  size: 16,
                  color: isDarkMode ? Colors.white54 : Colors.black45,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildTitleField(bool isDarkMode, Color accentColor) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        // Staggered animation - begins when dialog animation is 60% complete
        final titleAnimation = CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.2, 1.0, curve: Curves.easeOutBack),
        );

        return Transform.translate(
          offset: Offset(0, 20 - (20 * titleAnimation.value)),
          child: Opacity(
            opacity: titleAnimation.value,
            child: TextField(
              controller: _titleController,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'Title',
                hintStyle: TextStyle(
                  color: isDarkMode ? Colors.white54 : Colors.black54,
                  fontWeight: FontWeight.normal,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDarkMode ? Colors.white30 : Colors.black12,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: accentColor, width: 2),
                ),
                filled: true,
                fillColor: isDarkMode ? Colors.black : const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContentField(bool isDarkMode, Color accentColor) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        // Staggered animation - begins when dialog animation is 70% complete
        final contentAnimation = CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.3, 1.0, curve: Curves.easeOutBack),
        );

        return Transform.translate(
          offset: Offset(0, 20 - (20 * contentAnimation.value)),
          child: Opacity(
            opacity: contentAnimation.value,
            child: TextField(
              controller: _contentController,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
              maxLines: 5,
              decoration: InputDecoration(
                hintText:
                    'Share your thoughts, experiences, or ask for support...',
                hintStyle: TextStyle(
                  color: isDarkMode ? Colors.white54 : Colors.black54,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDarkMode ? Colors.white30 : Colors.black12,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: accentColor, width: 2),
                ),
                filled: true,
                fillColor: isDarkMode ? Colors.black : const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogActions(bool isDarkMode, Color accentColor) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        // Staggered animation - begins when dialog animation is 80% complete
        final actionsAnimation = CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.4, 1.0, curve: Curves.easeOutBack),
        );

        return Transform.translate(
          offset: Offset(0, 20 - (20 * actionsAnimation.value)),
          child: Opacity(
            opacity: actionsAnimation.value,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor:
                        isDarkMode ? Colors.white70 : Colors.black54,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  child: LocalizedText(
                    'cancel',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: accentColor.withAlpha(127),
                    elevation: 2,
                    shadowColor: accentColor.withAlpha(76),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
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
                          : LocalizedText(
                            'post',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _submitPost() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    // Play a reverse animation before closing the dialog
    _animationController.reverse().then((_) {
      widget.onCreatePost(title, content);
      Navigator.of(context).pop();
    });
  }
}
