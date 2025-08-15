import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/post_model.dart';
import 'services/forum_service.dart';
import 'services/auth_service.dart';
import 'theme_provider.dart';
import 'accessibility_provider.dart';
import 'post_detail_page.dart';
import 'widgets/post_card.dart';
import 'widgets/post_creation_dialog.dart';
import 'auth_page.dart';
import 'utils/animation_utils.dart';
import 'localization/localized_text.dart';
import 'localization/base_screen.dart';

class ForumPage extends BaseScreen {
  const ForumPage({super.key});

  @override
  State<ForumPage> createState() => _ForumPageState();
}

class _ForumPageState extends BaseScreenState<ForumPage> {
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
    
    // Always load posts regardless of login status
    setState(() {
      _isCheckingAuth = false;
    });
    _loadPosts();
    
    // If not logged in, show auth page after loading posts
    if (!authService.isLoggedIn) {
      debugPrint('User not logged in, but still loading posts');
      // Optionally navigate to auth page if you want to require login
      // _navigateToAuthPage();
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
      debugPrint('Loading posts in ForumPage');
      
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!mounted) return;
      
      final posts = await _forumService.getPosts();
      
      debugPrint('Loaded ${posts.length} posts in ForumPage');
      
      if (!mounted) return;
      
      setState(() {
        _posts = posts;
        _isLoading = false;
      });
      
      // If posts are still empty after trying to load them
      if (_posts.isEmpty) {
        debugPrint('Posts list is still empty after loading');
        
        // Create some fallback posts directly
        final hardcodedPost = Post(
          id: 'fallback-post-1',
          title: 'Welcome to the Community Forum',
          content: 'This is a fallback post created directly in the UI when no posts could be loaded.',
          authorId: 'system',
          authorName: 'System',
          createdAt: DateTime.now(),
          likes: 0,
          replies: [],
          isAnonymous: true,
        );
        
        setState(() {
          _posts = [hardcodedPost];
        });
      }
    } catch (e) {
      debugPrint('Error loading posts in ForumPage: ${e.toString()}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading posts. Using fallback content.'),
            backgroundColor: Colors.orange,
          ),
        );
        
        // Create a fallback post on error
        final errorPost = Post(
          id: 'error-post-1',
          title: 'Welcome to the Forum',
          content: 'Unable to load posts at the moment. Please try again later.',
          authorId: 'system',
          authorName: 'System',
          createdAt: DateTime.now(),
          likes: 0,
          replies: [],
          isAnonymous: true,
        );
        
        setState(() {
          _posts = [errorPost];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _filterPosts() async {
    if (_searchQuery.isEmpty) {
      _posts = await _forumService.getPosts();
    } else {
      _posts = await _forumService.searchPosts(_searchQuery);
    }
  }

  Future<void> _handleCreatePost(String title, String content) async {
    try {
      final newPost = await _forumService.addPost(title, content);
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

  Future<void> _handleLikePost(Post post) async {
    try {
      final result = await _forumService.likePost(post.id);
      final updatedPosts = await _forumService.getPosts();
      
      setState(() {
        _posts = updatedPosts;
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
    ).then((_) async {
      // Refresh posts when returning from details page
      if (!mounted) return;
      
      final updatedPosts = await _forumService.getPosts();
      
      setState(() {
        _posts = updatedPosts;
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
  Widget buildScreen(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final highContrastMode = accessibilityProvider.highContrastMode;
    final accentColor = isDarkMode ? const Color(0xFF8A4FFF) : const Color(0xFFE53935);

    // If checking auth, show loading
    if (_isCheckingAuth) {
      return Scaffold(
        backgroundColor: (highContrastMode && isDarkMode) 
            ? Colors.black 
            : (isDarkMode ? const Color(0xFF111827) : Colors.white),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: (highContrastMode && isDarkMode) 
          ? Colors.black 
          : (isDarkMode ? const Color(0xFF111827) : Colors.white),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
          backgroundColor: (highContrastMode && isDarkMode) 
              ? Colors.black 
              : (isDarkMode ? const Color(0xFF111827) : Colors.white),
          elevation: 0,
          automaticallyImplyLeading: false,
          titleSpacing: 0,
          title: Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 12.0),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.forum_outlined,
                    color: accentColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LocalizedText(
                      'forum',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ).withEntranceAnimation(),
                    LocalizedText(
                      'safeSpaceToShare',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ).withEntranceAnimation(delay: const Duration(milliseconds: 100)),
                  ],
                ),
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
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
                    displacement: 40,
                    child: _posts.isEmpty
                        ? _buildEmptyState()
                        : StaggeredAnimationList(
                            itemCount: _posts.length + 1, // +1 for info card at bottom
                            padding: const EdgeInsets.all(12),
                            initialDelay: const Duration(milliseconds: 400),
                            itemBuilder: (context, index) {
                              if (index == _posts.length) {
                                return _buildInfoCard();
                              }
                              final post = _posts[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
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
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor,
            accentColor.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: ThemeProvider.animationDurationMedium,
            width: 42,
            height: 42,
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
                  fontSize: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Welcome, ${authService.username}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isGuest 
                    ? 'You are browsing as a guest'
                    : 'Logged in as ${authService.userId}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
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
                size: 18,
              ),
              tooltip: 'Logout',
              constraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
              padding: EdgeInsets.zero,
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
            size: 60,
            color: isDarkMode ? Colors.white38 : Colors.black26,
          ),
          const SizedBox(height: 14),
          LocalizedText(
            'noPostsYet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          LocalizedText(
            'beTheFirstToStartConversation',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white54 : Colors.black45,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _showPostCreationDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDarkMode ? const Color(0xFF8A4FFF) : const Color(0xFFE53935),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(
              Icons.add, 
              color: Colors.white,
              size: 18,
            ),
            label: LocalizedText(
              'createPost',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
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
      height: 44,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black87,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: 'Search posts...',
          hintStyle: TextStyle(
            color: isDarkMode ? Colors.white54 : Colors.black54,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search, 
            color: isDarkMode ? Colors.white54 : Colors.black54,
            size: 18,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear, 
                    color: isDarkMode ? Colors.white54 : Colors.black54,
                    size: 16,
                  ),
                  onPressed: () {
                    _searchController.clear();
                  },
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final accentColor = isDarkMode ? const Color(0xFF8A4FFF) : const Color(0xFFE53935);
    
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite,
            color: accentColor,
            size: 16,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'This is a safe, moderated space. All posts are anonymous and supportive.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDarkMode ? Colors.white.withOpacity(0.8) : Colors.black87.withOpacity(0.8),
                fontSize: 12,
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
          elevation: 3,
          label: const Text(
            'Create Post',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          icon: const Icon(
            Icons.add,
            size: 18,
          ),
          extendedPadding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    ).withEntranceAnimation(
      delay: const Duration(milliseconds: 600),
    );
  }
} 