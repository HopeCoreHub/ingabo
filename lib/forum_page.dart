import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'models/post_model.dart';
import 'services/forum_service.dart';
import 'services/auth_service.dart';
import 'theme_provider.dart';
import 'post_detail_page.dart';
import 'widgets/post_card.dart';
import 'widgets/post_creation_dialog.dart';
import 'auth_page.dart';
import 'utils/animation_utils.dart';

class ForumPage extends StatefulWidget {
  const ForumPage({super.key});

  @override
  State<ForumPage> createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage> {
  final TextEditingController _searchController = TextEditingController();
  late ForumService _forumService;
  List<Post> _posts = [];
  bool _isLoading = true;
  String _searchQuery = '';
  bool _isCheckingAuth = true;

  @override
  void initState() {
    super.initState();
    _forumService = ForumService();
    _searchController.addListener(_onSearchChanged);
    
    // Use a post-frame callback to check auth status after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkAuthStatus();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Set the auth service when dependencies change
    final authService = Provider.of<AuthService>(context, listen: false);
    _forumService.setAuthService(authService);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _filterPosts();
    });
  }

  void _checkAuthStatus() {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    if (!authService.isLoggedIn) {
      // Navigate to auth page if not logged in
      _navigateToAuthPage();
    } else {
      // User is already logged in, load posts
      setState(() {
        _isCheckingAuth = false;
      });
      _loadPosts();
    }
  }

  void _navigateToAuthPage() {
    // Ensure we're not in a build phase
    Future.microtask(() {
      if (!mounted) return;
      
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const AuthPage())
      ).then((_) {
        if (!mounted) return;
        
        // When returning from auth page, check if now logged in
        final authService = Provider.of<AuthService>(context, listen: false);
        if (authService.isLoggedIn) {
          setState(() {
            _isCheckingAuth = false;
          });
          _loadPosts();
        } else {
          // If still not logged in, navigate back (to home)
          Navigator.of(context).pop();
        }
      });
    });
  }

  Future<void> _loadPosts() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!mounted) return;
      
      setState(() {
        _posts = _forumService.getPosts();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading posts: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterPosts() {
    if (_searchQuery.isEmpty) {
      _posts = _forumService.getPosts();
    } else {
      _posts = _forumService.searchPosts(_searchQuery);
    }
  }

  void _handleCreatePost(String title, String content) {
    try {
      final newPost = _forumService.addPost(title, content);
      setState(() {
        _posts = [newPost, ..._posts];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating post: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showPostCreationDialog() {
    showDialog(
      context: context,
      builder: (context) => PostCreationDialog(
        onCreatePost: _handleCreatePost,
      ),
    );
  }

  void _handleLikePost(Post post) {
    try {
      final result = _forumService.likePost(post.id);
      setState(() {
        _posts = _forumService.getPosts();
      });
      
      // Show appropriate feedback based on the result
      if (result == LikeResult.alreadyLiked) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('You have already liked this post'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error liking post: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToPostDetail(Post post, {bool focusReply = false}) {
    Navigator.push(
      context,
      AnimationUtils.customPageRoute(
        page: PostDetailPage(
          post: post, 
          focusReply: focusReply,
        ),
      ),
    ).then((_) {
      // Refresh posts when returning from details page
      if (!mounted) return;
      
      setState(() {
        _posts = _forumService.getPosts();
      });
    });
  }

  void _handleLogout() {
    final authService = Provider.of<AuthService>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              authService.logout();
              Navigator.pop(context); // Close dialog
              _navigateToAuthPage();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final accentColor = isDarkMode ? const Color(0xFF8A4FFF) : const Color(0xFFE53935);

    // If checking auth, show loading
    if (_isCheckingAuth) {
      return Scaffold(
        backgroundColor: isDarkMode ? const Color(0xFF111827) : Colors.white,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF111827) : Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          backgroundColor: isDarkMode ? const Color(0xFF111827) : Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          titleSpacing: 0,
          title: Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Forum',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ).withEntranceAnimation(),
                const SizedBox(height: 2),
                Text(
                  'Safe space to share',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ).withEntranceAnimation(delay: const Duration(milliseconds: 100)),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildUserInfoCard().withEntranceAnimation(
            delay: const Duration(milliseconds: 200),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _buildSearchBar().withEntranceAnimation(
              delay: const Duration(milliseconds: 300),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadPosts,
                    color: accentColor,
                    backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                    displacement: 50,
                    child: _posts.isEmpty
                        ? _buildEmptyState()
                        : StaggeredAnimationList(
                            itemCount: _posts.length + 1, // +1 for info card at bottom
                            padding: const EdgeInsets.all(16),
                            initialDelay: const Duration(milliseconds: 400),
                            itemBuilder: (context, index) {
                              if (index == _posts.length) {
                                return _buildInfoCard();
                              }
                              final post = _posts[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: PostCard(
                                post: post,
                                  index: index,
                                onTap: () => _navigateToPostDetail(post),
                                  onLike: () => _handleLikePost(post),
                                  onReply: () => _navigateToPostDetail(post, focusReply: true),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: _buildCreatePostButton(),
    );
  }

  Widget _buildUserInfoCard() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authService = Provider.of<AuthService>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final accentColor = isDarkMode ? const Color(0xFF8A4FFF) : const Color(0xFFE53935);
    
    // Get first letter of username for avatar
    final String firstLetter = (authService.username ?? 'A')[0].toUpperCase();
    final bool isGuest = authService.username == 'Guest';
    
    return AnimatedContainer(
      duration: ThemeProvider.animationDurationMedium,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor,
            accentColor.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: ThemeProvider.animationDurationMedium,
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                firstLetter,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${authService.username}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isGuest 
                    ? 'You are browsing as a guest'
                    : 'Logged in as ${authService.userId}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          AnimatedContainer(
            duration: ThemeProvider.animationDurationMedium,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.15),
            ),
            child: IconButton(
            onPressed: _handleLogout,
            icon: const Icon(
              Icons.logout,
              color: Colors.white,
            ),
            tooltip: 'Logout',
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.forum_outlined,
            size: 70,
            color: isDarkMode ? Colors.white38 : Colors.black26,
          ),
          const SizedBox(height: 16),
          Text(
            'No posts yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to start a conversation',
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.white54 : Colors.black45,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showPostCreationDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDarkMode ? const Color(0xFF8A4FFF) : const Color(0xFFE53935),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Create Post',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return AnimatedContainer(
      duration: ThemeProvider.animationDurationMedium,
      height: 50,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          hintText: 'Search posts...',
          hintStyle: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54),
          prefixIcon: Icon(Icons.search, color: isDarkMode ? Colors.white54 : Colors.black54),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: isDarkMode ? Colors.white54 : Colors.black54),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final accentColor = isDarkMode ? const Color(0xFF8A4FFF) : const Color(0xFFE53935);
    
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite,
            color: accentColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'This is a safe, moderated space. All posts are anonymous and supportive.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDarkMode ? Colors.white.withOpacity(0.8) : Colors.black87.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreatePostButton() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final accentColor = isDarkMode ? const Color(0xFF8A4FFF) : const Color(0xFFE53935);
    
    return AnimatedScale(
      scale: 1.0,
      duration: ThemeProvider.animationDurationShort,
      curve: ThemeProvider.animationCurveDefault,
      child: AnimatedOpacity(
        opacity: 1.0,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeIn,
        child: FloatingActionButton.extended(
          onPressed: _showPostCreationDialog,
          backgroundColor: accentColor,
          elevation: 4,
          label: const Text('Create Post'),
          icon: const Icon(Icons.add),
          extendedPadding: const EdgeInsets.symmetric(horizontal: 24),
        ),
      ),
    ).withEntranceAnimation(
      delay: const Duration(milliseconds: 600),
    );
  }
} 