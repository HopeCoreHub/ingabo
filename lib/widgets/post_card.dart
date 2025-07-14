import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import '../models/post_model.dart';
import '../services/forum_service.dart';
import 'animated_card.dart';

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
    final forumService = Provider.of<ForumService>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    
    // Get first letter of author's name for avatar
    final String firstLetter = post.authorName.isNotEmpty 
        ? post.authorName[0].toUpperCase() 
        : 'A';
    
    return FutureBuilder<bool>(
      future: forumService.hasUserLikedPost(post.id),
      builder: (context, snapshot) {
        // Default to false if the future hasn't completed yet
        final hasLiked = snapshot.data ?? false;
    
    return AnimatedCard(
      onTap: onTap,
      animationDelayIndex: index,
      elevation: 3,
      borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                _buildAvatar(firstLetter),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorName,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getTimeAgo(post.createdAt),
                        style: TextStyle(
                          color: isDarkMode ? Colors.white54 : Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                post.title,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
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
                color: isDarkMode ? Colors.white70 : Colors.black87,
                  fontSize: 14,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Divider(
              color: isDarkMode ? const Color(0xFF2D3748).withOpacity(0.6) : const Color(0xFFE2E8F0),
              height: 1,
            ),
          ),
          _buildActionBar(isDarkMode, hasLiked),
        ],
      ),
        );
      }
    );
  }

  Widget _buildAvatar(String firstLetter) {
    return Hero(
      tag: 'post-avatar-${post.id}',
      child: AnimatedContainer(
        duration: ThemeProvider.animationDurationMedium,
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF8A4FFF),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8A4FFF).withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            firstLetter,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionBar(bool isDarkMode, bool hasLiked) {
    return Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
              _buildIconButton(
                icon: hasLiked ? Icons.favorite : Icons.favorite_border,
                color: hasLiked ? Colors.red : isDarkMode ? Colors.white54 : Colors.black54,
                        onPressed: onLike,
                      ),
                      const SizedBox(width: 4),
              AnimatedDefaultTextStyle(
                duration: ThemeProvider.animationDurationShort,
                        style: TextStyle(
                  color: hasLiked ? Colors.red : (isDarkMode ? Colors.white54 : Colors.black54),
                          fontSize: 14,
                  fontWeight: hasLiked ? FontWeight.bold : FontWeight.normal,
                        ),
                child: Text('${post.likes}'),
                      ),
                      const SizedBox(width: 16),
              _buildIconButton(
                icon: Icons.chat_bubble_outline,
                color: isDarkMode ? Colors.white54 : Colors.black54,
                        onPressed: onReply,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${post.replies.length}',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white54 : Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
          _buildReplyButton(isDarkMode),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return AnimatedScale(
      scale: 1.0,
      duration: ThemeProvider.animationDurationShort,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: color),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        splashRadius: 20,
      ),
    );
  }

  Widget _buildReplyButton(bool isDarkMode) {
    return AnimatedContainer(
      duration: ThemeProvider.animationDurationShort,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF8A4FFF).withOpacity(0.1),
      ),
      child: TextButton(
                    onPressed: onReply,
                    style: ButtonStyle(
                      overlayColor: MaterialStateProperty.all(Colors.transparent),
          padding: MaterialStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
                    ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.reply,
              size: 16,
              color: const Color(0xFF8A4FFF),
            ),
            const SizedBox(width: 4),
            const Text(
                      'Reply',
                      style: TextStyle(
                color: Color(0xFF8A4FFF),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
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