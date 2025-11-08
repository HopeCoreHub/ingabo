import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import '../models/post_model.dart';
import '../models/reply_model.dart';
import '../services/forum_service.dart';
import '../services/auth_service.dart';
import '../services/content_reporting_service.dart';
import 'content_report_dialog.dart';
import '../localization/localized_text.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final Function() onTap;
  final Function() onLike;
  final Function(String postId, String content) onReply;
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
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final TextEditingController _replyController = TextEditingController();
  bool _showReplyInput = false;
  bool _isSendingReply = false;
  List<Reply> _replies = [];

  @override
  void initState() {
    super.initState();
    _loadReplies();
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _loadReplies() async {
    try {
      final forumService = Provider.of<ForumService>(context, listen: false);
      final replies = await forumService.getRepliesForPost(widget.post.id);
      if (mounted) {
        setState(() {
          _replies = replies;
        });
      }
    } catch (e) {
      debugPrint('Error loading replies: $e');
    }
  }

  Future<void> _handleSendReply() async {
    if (_replyController.text.trim().isEmpty) return;

    setState(() {
      _isSendingReply = true;
    });

    try {
      await widget.onReply(widget.post.id, _replyController.text.trim());
      _replyController.clear();
      setState(() {
        _showReplyInput = false;
        _isSendingReply = false;
      });
      // Reload replies to show the new one
      _loadReplies();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSendingReply = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending reply: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authService = Provider.of<AuthService>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;

    // Determine display name: show real name for author, "Anonymous" for others if isAnonymous
    final String currentUserId = authService.userId ?? '';
    final bool isAuthor = currentUserId == widget.post.authorId;
    final bool shouldShowAnonymous = widget.post.isAnonymous && !isAuthor;

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
                            widget.post.authorName,
                            style: TextStyle(
                              color: isDarkMode ? Colors.white60 : Colors.black54,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                    const SizedBox(width: 8),
                    Text(
                      _getFormattedTime(widget.post.createdAt),
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
                      widget.post.content,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                    // Like count and action buttons in bottom right
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Like button
                          InkWell(
                            onTap: () {
                              final authService = Provider.of<AuthService>(context, listen: false);
                              if (!authService.isLoggedIn) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please log in to like posts'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }
                              widget.onLike();
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    widget.post.likedBy.contains(currentUserId)
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    size: 16,
                                    color: widget.post.likedBy.contains(currentUserId)
                                        ? Colors.red
                                        : (isDarkMode ? Colors.white60 : Colors.black54),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${widget.post.likes}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDarkMode ? Colors.white60 : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Reply button
                          InkWell(
                            onTap: () {
                              final authService = Provider.of<AuthService>(context, listen: false);
                              if (!authService.isLoggedIn) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please log in to reply'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }
                              setState(() {
                                _showReplyInput = !_showReplyInput;
                              });
                            },
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
                          if (widget.onEdit != null)
                            InkWell(
                              onTap: widget.onEdit,
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
                          if (widget.onDelete != null)
                            InkWell(
                              onTap: widget.onDelete,
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
              // Reply input (shown when reply button is clicked)
              if (_showReplyInput) ...[
                const SizedBox(height: 8),
                _buildReplyInput(context, isDarkMode),
              ],
              // Replies list
              if (_replies.isNotEmpty) ...[
                const SizedBox(height: 8),
                ..._replies.map((reply) => _buildReplyBubble(reply, isDarkMode)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReplyInput(BuildContext context, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withAlpha(15)
            : Colors.grey.withAlpha(15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withAlpha(38)
              : Colors.black.withAlpha(20),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _replyController,
              maxLines: 3,
              minLines: 1,
              textInputAction: TextInputAction.newline,
              keyboardType: TextInputType.multiline,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
                fontSize: 13,
              ),
              decoration: InputDecoration(
                hintText: 'Type a reply...',
                hintStyle: TextStyle(
                  color: isDarkMode ? Colors.white54 : Colors.black54,
                  fontSize: 13,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF8A4FFF) : const Color(0xFFE53935),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: _isSendingReply
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white, size: 18),
              onPressed: _isSendingReply ? null : _handleSendReply,
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyBubble(Reply reply, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LocalizedText(
                'anonymous',
                style: TextStyle(
                  color: isDarkMode ? Colors.white54 : Colors.black54,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _getFormattedTime(reply.createdAt),
                style: TextStyle(
                  color: isDarkMode ? Colors.white38 : Colors.black38,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.white.withAlpha(20)
                  : Colors.grey.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDarkMode
                    ? Colors.white.withAlpha(38)
                    : Colors.black.withAlpha(15),
                width: 1,
              ),
            ),
            child: Text(
              reply.content,
              style: TextStyle(
                color: isDarkMode ? Colors.white.withAlpha(222) : Colors.black87,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showReportDialog(BuildContext context) async {
    final preview =
        widget.post.content.length > 100
            ? '${widget.post.content.substring(0, 100)}...'
            : widget.post.content;

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => ContentReportDialog(
            contentId: widget.post.id,
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
