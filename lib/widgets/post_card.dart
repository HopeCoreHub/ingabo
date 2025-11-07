import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import '../accessibility_provider.dart';
import '../models/post_model.dart';
import '../services/forum_service.dart';
import '../services/auth_service.dart';
import '../utils/accessibility_utils.dart';
import 'animated_card.dart';
import 'accessible_container.dart';
import '../services/content_reporting_service.dart';
import 'content_report_dialog.dart';
import '../localization/localized_text.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final Function() onTap;
  final Function() onLike;
  final Function() onReply;
  final int index;

  const PostCard({
    super.key,
    required this.post,
    required this.onTap,
    required this.onLike,
    required this.onReply,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
    final forumService = Provider.of<ForumService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    final highContrastMode = accessibilityProvider.highContrastMode;

    // Determine display name: show real name for author, "Anonymous" for others if isAnonymous
    final String currentUserId = authService.userId ?? '';
    final bool isAuthor = currentUserId == post.authorId;
    final bool shouldShowAnonymous = post.isAnonymous && !isAuthor;

    // Get first letter for avatar (use post.authorName for avatar, even if displaying Anonymous)
    final String firstLetter =
        post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : 'A';

    return FutureBuilder<bool>(
      future: forumService.hasUserLikedPost(post.id),
      builder: (context, snapshot) {
        // Default to false if the future hasn't completed yet
        final hasLiked = snapshot.data ?? false;

        final cardWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  _buildAvatar(firstLetter, context),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        shouldShowAnonymous
                            ? LocalizedText(
                              'anonymous',
                              style: TextStyle(
                                color: AccessibilityUtils.getAccessibleColor(
                                  context,
                                  isDarkMode ? Colors.white : Colors.black87,
                                ),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            )
                            : Text(
                              post.authorName,
                              style: TextStyle(
                                color: AccessibilityUtils.getAccessibleColor(
                                  context,
                                  isDarkMode ? Colors.white : Colors.black87,
                                ),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                        const SizedBox(height: 2),
                        Text(
                          _getTimeAgo(post.createdAt),
                          style: TextStyle(
                            color: AccessibilityUtils.getAccessibleColor(
                              context,
                              isDarkMode ? Colors.white54 : Colors.black54,
                            ),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                post.title,
                style: TextStyle(
                  color: AccessibilityUtils.getAccessibleColor(
                    context,
                    isDarkMode ? Colors.white : Colors.black87,
                  ),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                post.content,
                style: TextStyle(
                  color: AccessibilityUtils.getAccessibleColor(
                    context,
                    isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                  fontSize: 14,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Divider(
                color:
                    highContrastMode
                        ? (isDarkMode
                            ? Colors.white.withOpacity(0.6)
                            : Colors.black.withOpacity(0.6))
                        : (isDarkMode
                            ? const Color(0xFF2D3748).withOpacity(0.6)
                            : const Color(0xFFE2E8F0)),
                height: 1,
              ),
            ),
            _buildActionBar(context, isDarkMode, hasLiked, highContrastMode),
          ],
        );

        // Return either accessible card or animated card based on high contrast mode
        if (highContrastMode) {
          return AccessibleCard(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: EdgeInsets.zero,
            child: cardWidget,
          );
        } else {
          return AnimatedCard(
            onTap: onTap,
            animationDelayIndex: index,
            elevation: 3,
            borderRadius: BorderRadius.circular(16),
            child: cardWidget,
          );
        }
      },
    );
  }

  Widget _buildAvatar(String firstLetter, BuildContext context) {
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
    final highContrastMode = accessibilityProvider.highContrastMode;

    final avatarColor =
        highContrastMode
            ? Colors
                .black // Use simple colors for high contrast
            : const Color(0xFF8A4FFF);

    final borderColor =
        highContrastMode ? Colors.white : Colors.white.withOpacity(0.2);

    return Hero(
      tag: 'post-avatar-${post.id}',
      child: AnimatedContainer(
        duration: ThemeProvider.animationDurationMedium,
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: avatarColor,
          boxShadow:
              highContrastMode
                  ? null
                  : [
                    BoxShadow(
                      color: const Color(0xFF8A4FFF).withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          border: Border.all(
            color: borderColor,
            width: highContrastMode ? 2.0 : 1.5,
          ),
        ),
        child: Center(
          child: Text(
            firstLetter,
            style: TextStyle(
              color: highContrastMode ? Colors.white : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionBar(
    BuildContext context,
    bool isDarkMode,
    bool hasLiked,
    bool highContrastMode,
  ) {
    // Adjust colors for high contrast
    final regularIconColor = AccessibilityUtils.getAccessibleColor(
      context,
      isDarkMode ? Colors.white54 : Colors.black54,
    );

    final likeColor = highContrastMode ? Colors.white : Colors.red;

    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildIconButton(
                context: context,
                icon: hasLiked ? Icons.favorite : Icons.favorite_border,
                color: hasLiked ? likeColor : regularIconColor,
                onPressed: onLike,
              ),
              const SizedBox(width: 4),
              AnimatedDefaultTextStyle(
                duration: ThemeProvider.animationDurationShort,
                style: TextStyle(
                  color: hasLiked ? likeColor : regularIconColor,
                  fontSize: 14,
                  fontWeight: hasLiked ? FontWeight.bold : FontWeight.normal,
                ),
                child: Text('${post.likes}'),
              ),
              const SizedBox(width: 16),
              _buildIconButton(
                context: context,
                icon: Icons.chat_bubble_outline,
                color: regularIconColor,
                onPressed: onReply,
              ),
              const SizedBox(width: 4),
              Text(
                '${post.replies.length}',
                style: TextStyle(color: regularIconColor, fontSize: 14),
              ),
              const SizedBox(width: 12),
              _buildIconButton(
                context: context,
                icon: Icons.flag_outlined,
                color: regularIconColor,
                onPressed: () => _showReportDialog(context),
              ),
            ],
          ),
          _buildReplyButton(context, isDarkMode, highContrastMode),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
    final highContrastMode = accessibilityProvider.highContrastMode;

    final animationDuration =
        highContrastMode
            ? const Duration(
              milliseconds: 100,
            ) // Reduced animation for accessibility
            : ThemeProvider.animationDurationShort;

    return AnimatedScale(
      scale: 1.0,
      duration: animationDuration,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: color),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        splashRadius: 20,
      ),
    );
  }

  Widget _buildReplyButton(
    BuildContext context,
    bool isDarkMode,
    bool highContrastMode,
  ) {
    final accentColor =
        highContrastMode
            ? (isDarkMode ? Colors.white : Colors.black)
            : const Color(0xFF8A4FFF);

    final bgColor =
        highContrastMode ? Colors.transparent : accentColor.withOpacity(0.1);

    return AnimatedContainer(
      duration: ThemeProvider.animationDurationShort,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: bgColor,
        border:
            highContrastMode ? Border.all(color: accentColor, width: 2) : null,
      ),
      child: TextButton(
        onPressed: onReply,
        style: ButtonStyle(
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.reply, size: 16, color: accentColor),
            const SizedBox(width: 4),
            Text(
              'Reply',
              style: TextStyle(
                color: accentColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showReportDialog(BuildContext context) async {
    // Get a preview of the post content
    final preview =
        post.content.length > 100
            ? '${post.content.substring(0, 100)}...'
            : post.content;

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => ContentReportDialog(
            contentId: post.id,
            contentType: ContentType.forumPost,
            contentPreview: preview,
          ),
    );

    if (result == true) {
      // Show confirmation
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Thank you for reporting this post. We will review it promptly.',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
