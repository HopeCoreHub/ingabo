import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import '../models/post_model.dart';
import '../services/forum_service.dart';
import '../services/auth_service.dart';
import '../services/content_reporting_service.dart';
import 'content_report_dialog.dart';
import '../localization/localized_text.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final Function() onTap;
  final Function() onLike;
  final Function() onReply;
  final Function()? onDelete;
  final Function()? onEdit;
  final int index;

  const PostCard({
    super.key,
    required this.post,
    required this.onTap,
    required this.onLike,
    required this.onReply,
    this.onDelete,
    this.onEdit,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final forumService = Provider.of<ForumService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;

    // Determine display name: show real name for author, "Anonymous" for others if isAnonymous
    final String currentUserId = authService.userId ?? '';
    final bool isAuthor = currentUserId == post.authorId;
    final bool shouldShowAnonymous = post.isAnonymous && !isAuthor;

    return FutureBuilder<bool>(
      future: forumService.hasUserLikedPost(post.id),
      builder: (context, snapshot) {
        final hasLiked = snapshot.data ?? false;

        // WhatsApp-style message bubble
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author name and time
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 4),
                    child: Row(
                      children: [
                        shouldShowAnonymous
                            ? LocalizedText(
                                'anonymous',
                                style: TextStyle(
                                  color: isDarkMode ? Colors.white60 : Colors.black54,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                            : Text(
                                post.authorName,
                                style: TextStyle(
                                  color: isDarkMode ? Colors.white60 : Colors.black54,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                        const SizedBox(width: 8),
                        Text(
                          _getFormattedTime(post.createdAt),
                          style: TextStyle(
                            color: isDarkMode ? Colors.white38 : Colors.black38,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Message bubble
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.white.withAlpha(25)
                          : Colors.grey.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDarkMode
                            ? Colors.white.withAlpha(51)
                            : Colors.black.withAlpha(25),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Message content (no title)
                        Text(
                          post.content,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black87,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Action buttons row
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Reply button
                            InkWell(
                              onTap: onReply,
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                child: Icon(
                                  Icons.reply,
                                  size: 16,
                                  color: isDarkMode ? Colors.white60 : Colors.black54,
                                ),
                              ),
                            ),
                            // Flag/Report or Delete/Edit for own posts
                            if (isAuthor) ...[
                              const SizedBox(width: 8),
                              // Edit button
                              if (onEdit != null)
                                InkWell(
                                  onTap: onEdit,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    child: Icon(
                                      Icons.edit_outlined,
                                      size: 16,
                                      color: isDarkMode ? Colors.white60 : Colors.black54,
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 8),
                              // Delete button
                              if (onDelete != null)
                                InkWell(
                                  onTap: onDelete,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    child: Icon(
                                      Icons.delete_outline,
                                      size: 16,
                                      color: Colors.red.withAlpha(204),
                                    ),
                                  ),
                                ),
                            ] else ...[
                              const SizedBox(width: 8),
                              // Flag/Report button
                              InkWell(
                                onTap: () => _showReportDialog(context),
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  child: Icon(
                                    Icons.flag_outlined,
                                    size: 16,
                                    color: isDarkMode ? Colors.white60 : Colors.black54,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showReportDialog(BuildContext context) async {
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

    if (result == true && context.mounted) {
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

  String _getFormattedTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final difference = today.difference(messageDate).inDays;

    // Format time
    final hour = dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final amPm = dateTime.hour < 12 ? 'AM' : 'PM';
    final timeStr = '${hour == 0 ? 12 : hour}:$minute $amPm';

    if (difference == 0) {
      // Today - show time only
      return timeStr;
    } else if (difference == 1) {
      // Yesterday
      return 'Yesterday $timeStr';
    } else if (difference < 7) {
      // This week - show day name
      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return '${days[dateTime.weekday - 1]} $timeStr';
    } else if (dateTime.year == now.year) {
      // This year - show day and month
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[dateTime.month - 1]} ${dateTime.day}, $timeStr';
    } else {
      // Past year - show day, month, and year
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}, $timeStr';
    }
  }
}
