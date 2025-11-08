import 'package:uuid/uuid.dart';
import '../models/post_model.dart';
import '../models/reply_model.dart';
import 'auth_service.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'firebase_realtime_service.dart';

// Define like result enum at the top level
enum LikeResult { success, alreadyLiked }

class ForumService {
  static final ForumService _instance = ForumService._internal();
  final List<Post> _posts = []; // Local cache of posts
  final List<Reply> _replies = []; // Local cache of replies
  final uuid = const Uuid();
  AuthService? _authService;

  // Use Realtime Database service
  final FirebaseRealtimeService _realtimeDB = FirebaseRealtimeService();

  factory ForumService() {
    return _instance;
  }

  ForumService._internal() {
    // Always add some guaranteed posts directly to the in-memory cache
    _addInitialPosts();

    // Then try to load from Firebase Realtime Database
    _loadPostsFromRealtimeDB();
  }

  // Add initial posts directly to the cache to ensure content is always available
  void _addInitialPosts() {
    debugPrint('Adding initial posts to ensure content availability');

    // Create some initial posts that will always be available
    final initialPost = Post(
      id: 'initial-post-1',
      title: 'Welcome to the Forum',
      content:
          'This space is for community support and discussion. Feel free to share your thoughts and experiences.',
      authorId: 'system',
      authorName: 'HopeCore Team',
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      likes: 5,
      replies: [],
      isAnonymous: false,
      likedBy: {'system'},
    );

    // Add to local cache
    _posts.add(initialPost);

    debugPrint('Added initial posts to cache');
  }

  // Load posts from Firebase Realtime Database
  Future<void> _loadPostsFromRealtimeDB() async {
    try {
      debugPrint('🔗 _loadPostsFromRealtimeDB() called');
      debugPrint('🔧 Realtime DB instance: $_realtimeDB');

      // Get posts from Realtime Database
      debugPrint('📡 Calling _realtimeDB.getAllPosts()...');
      final posts = await _realtimeDB.getAllPosts();
      debugPrint('✅ getAllPosts() returned ${posts.length} posts');

      if (posts.isNotEmpty) {
        // Clear existing posts and add the new ones
        debugPrint('🔄 Clearing existing posts and adding new ones');
        _posts.clear();
        _posts.addAll(posts);
        debugPrint('✅ Loaded ${posts.length} posts from Realtime Database');
      } else {
        debugPrint(
          '⚠️ No posts found in Realtime Database, creating sample posts',
        );
        await _realtimeDB.createSamplePosts();
        debugPrint('✅ Sample posts created, trying to load again...');

        // Try loading again
        final samplePosts = await _realtimeDB.getAllPosts();
        debugPrint(
          '📡 Second getAllPosts() returned ${samplePosts.length} posts',
        );
        if (samplePosts.isNotEmpty) {
          _posts.clear();
          _posts.addAll(samplePosts);
          debugPrint(
            '✅ Loaded ${samplePosts.length} sample posts from Realtime Database',
          );
        } else {
          debugPrint('❌ Still no posts after creating samples');
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading posts from Realtime Database: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
    }
  }

  // Method to set the auth service externally
  void setAuthService(AuthService authService) {
    _authService = authService;
  }

  String getCurrentUserId() {
    final authService = _authService ?? AuthService();
    return authService.userId ?? 'anonymous_user';
  }

  String getCurrentUsername() {
    final authService = _authService ?? AuthService();
    return authService.username ?? 'Anonymous';
  }

  bool isLoggedIn() {
    final authService = _authService ?? AuthService();
    return authService.isLoggedIn;
  }

  Future<List<Post>> getPosts() async {
    debugPrint('🚀 ForumService.getPosts() called');
    debugPrint('🗄️ Current _posts cache size: ${_posts.length}');

    // Always refresh posts from Firebase to ensure latest data
    try {
      debugPrint('🔄 Getting posts from Realtime Database');
      await _loadPostsFromRealtimeDB();
      debugPrint(
        '✅ Finished loading from Realtime Database, cache size: ${_posts.length}',
      );

      // Double check if posts are still empty after loading
      if (_posts.isEmpty) {
        debugPrint(
          '⚠️ Posts still empty after loading, adding hardcoded samples',
        );
        _addHardcodedSamplePosts();
        debugPrint('✅ Added hardcoded samples, cache size: ${_posts.length}');
      }
    } catch (e) {
      debugPrint('❌ Error in getPosts(): $e');
      if (_posts.isEmpty) {
        debugPrint('⚠️ Adding hardcoded samples due to error');
        _addHardcodedSamplePosts();
        debugPrint(
          '✅ Added hardcoded samples after error, cache size: ${_posts.length}',
        );
      }
    }

    // Return a sorted copy of posts (newest first)
    final sortedPosts = [..._posts];
    sortedPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    debugPrint('📤 Returning ${sortedPosts.length} posts to caller');
    return sortedPosts;
  }

  // Add hardcoded sample posts directly without trying to save to Firebase
  void _addHardcodedSamplePosts() {
    if (_posts.isNotEmpty) return; // Don't add samples if we already have posts

    debugPrint('Adding hardcoded sample posts');

    final samplePost1 = Post(
      id: 'sample-post-1',
      title: 'Welcome to the HopeCore Forum',
      content:
          'This is a safe space for sharing experiences and supporting each other. Feel free to join the conversation!',
      authorId: 'system',
      authorName: 'HopeCore Team',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      likes: 15,
      likedBy: {'user1', 'user2', 'user3'},
    );

    final samplePost2 = Post(
      id: 'sample-post-2',
      title: 'Tips for Managing Anxiety',
      content:
          'I\'ve found that deep breathing exercises, regular physical activity, and limiting caffeine really help with anxiety. What works for you?',
      authorId: 'sample_user_1',
      authorName: 'Anonymous',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      likes: 8,
      likedBy: {'user4', 'user5'},
    );

    final samplePost3 = Post(
      id: 'sample-post-3',
      title: 'Seeking Support for Difficult Times',
      content:
          'I\'m going through a really tough period right now. Has anyone used any of the support resources in the app and found them helpful?',
      authorId: 'sample_user_2',
      authorName: 'Anonymous',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      likes: 12,
      likedBy: {'user6', 'user7', 'user8'},
    );

    _posts.add(samplePost1);
    _posts.add(samplePost2);
    _posts.add(samplePost3);

    // Add replies to the posts
    final reply1 = Reply(
      id: 'sample-reply-1',
      postId: samplePost2.id,
      content:
          'Meditation has been life-changing for me. I use the Calm app for guided sessions.',
      authorId: 'sample_user_3',
      authorName: 'Anonymous',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      likes: 5,
    );

    final reply2 = Reply(
      id: 'sample-reply-2',
      postId: samplePost3.id,
      content:
          'The Mahoro AI assistant helped me a lot when I needed someone to talk to at 2am. It\'s surprisingly good!',
      authorId: 'sample_user_4',
      authorName: 'Anonymous',
      createdAt: DateTime.now().subtract(const Duration(hours: 12)),
      likes: 7,
    );

    _replies.add(reply1);
    _replies.add(reply2);

    // Update the posts' replies lists
    final post2Index = _posts.indexWhere((post) => post.id == samplePost2.id);
    if (post2Index != -1) {
      final post = _posts[post2Index];
      _posts[post2Index] = post.copyWith(replies: [...post.replies, reply1.id]);
    }

    final post3Index = _posts.indexWhere((post) => post.id == samplePost3.id);
    if (post3Index != -1) {
      final post = _posts[post3Index];
      _posts[post3Index] = post.copyWith(replies: [...post.replies, reply2.id]);
    }

    debugPrint('Added ${_posts.length} hardcoded sample posts');
  }

  Future<List<Post>> searchPosts(String query) async {
    if (query.isEmpty) {
      return getPosts();
    }

    final lowercaseQuery = query.toLowerCase();

    try {
      // Get all posts and filter locally
      final allPosts = await getPosts();

      return allPosts.where((post) {
        return post.title.toLowerCase().contains(lowercaseQuery) ||
            post.content.toLowerCase().contains(lowercaseQuery);
      }).toList();
    } catch (e) {
      debugPrint('Error searching posts: $e');

      // Fall back to local search
      final posts = await getPosts();
      return posts.where((post) {
        return post.title.toLowerCase().contains(lowercaseQuery) ||
            post.content.toLowerCase().contains(lowercaseQuery);
      }).toList();
    }
  }

  Future<Post> addPost(String title, String content) async {
    if (!isLoggedIn()) {
      throw Exception('User must be logged in to create a post');
    }

    final newPostId = uuid.v4();

    final newPost = Post(
      id: newPostId,
      title: title,
      content: content,
      authorId: getCurrentUserId(),
      authorName: getCurrentUsername(),
      createdAt: DateTime.now(),
      likes: 0,
      replies: [],
      isAnonymous: true,
      isSyncedWithCloud: false, // Initially not synced
    );

    try {
      // Check for connectivity first
      final connectivityResults = await Connectivity().checkConnectivity();
      final isOnline = !connectivityResults.contains(ConnectivityResult.none);

      if (!isOnline) {
        debugPrint('📵 Device is offline, saving post locally only');
        _posts.add(newPost);
        return newPost; // Return with isSyncedWithCloud = false
      }

      // Save to Realtime Database
      final savedPost = await _realtimeDB.addPost(newPost);

      if (savedPost != null) {
        // Add to local cache with synced flag set to true
        final syncedPost = savedPost.copyWith(isSyncedWithCloud: true);

        // Find and replace in cache if already exists, otherwise add
        final index = _posts.indexWhere((p) => p.id == syncedPost.id);
        if (index >= 0) {
          _posts[index] = syncedPost;
        } else {
          _posts.add(syncedPost);
        }

        return syncedPost;
      } else {
        // Add to local cache with synced flag set to false
        _posts.add(newPost);
        return newPost; // Return with isSyncedWithCloud = false
      }
    } catch (e) {
      debugPrint('Error adding post to Realtime Database: $e');

      // Add to local cache with synced flag set to false
      _posts.add(newPost);
      return newPost; // Return with isSyncedWithCloud = false
    }
  }

  Future<List<Reply>> getRepliesForPost(String postId) async {
    try {
      // Get replies from Realtime Database
      final replies = await _realtimeDB.getRepliesForPost(postId);

      if (replies.isNotEmpty) {
        // Update local cache
        for (var reply in replies) {
          final index = _replies.indexWhere((r) => r.id == reply.id);
          if (index != -1) {
            _replies[index] = reply;
          } else {
            _replies.add(reply);
          }
        }

        return replies;
      }

      // Fall back to local cache
      final postReplies =
          _replies.where((reply) => reply.postId == postId).toList();
      postReplies.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return postReplies;
    } catch (e) {
      debugPrint('Error getting replies from Realtime Database: $e');

      // Fall back to local cache
      final postReplies =
          _replies.where((reply) => reply.postId == postId).toList();
      postReplies.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return postReplies;
    }
  }

  Future<Reply> addReply(String postId, String content) async {
    if (!isLoggedIn()) {
      throw Exception('User must be logged in to reply to a post');
    }

    final newReplyId = uuid.v4();

    final newReply = Reply(
      id: newReplyId,
      postId: postId,
      content: content,
      authorId: getCurrentUserId(),
      authorName: getCurrentUsername(),
      createdAt: DateTime.now(),
      isAnonymous: true, // All replies are anonymous
    );

    try {
      // Save to Realtime Database
      final savedReply = await _realtimeDB.addReply(newReply);

      if (savedReply != null) {
        // Add to local cache
        _replies.add(savedReply);

        // Update the post's replies list in local cache
        final postIndex = _posts.indexWhere((post) => post.id == postId);
        if (postIndex != -1) {
          final post = _posts[postIndex];
          final updatedReplies = [...post.replies, savedReply.id];
          _posts[postIndex] = post.copyWith(replies: updatedReplies);
        }

        return savedReply;
      } else {
        // Add to local cache anyway
        _replies.add(newReply);

        // Update the post's replies list in local cache
        final postIndex = _posts.indexWhere((post) => post.id == postId);
        if (postIndex != -1) {
          final post = _posts[postIndex];
          final updatedReplies = [...post.replies, newReply.id];
          _posts[postIndex] = post.copyWith(replies: updatedReplies);
        }

        return newReply;
      }
    } catch (e) {
      debugPrint('Error adding reply to Realtime Database: $e');

      // Add to local cache anyway
      _replies.add(newReply);

      // Update the post's replies list in local cache
      final postIndex = _posts.indexWhere((post) => post.id == postId);
      if (postIndex != -1) {
        final post = _posts[postIndex];
        final updatedReplies = [...post.replies, newReply.id];
        _posts[postIndex] = post.copyWith(replies: updatedReplies);
      }

      return newReply;
    }
  }

  Future<LikeResult> likePost(String postId) async {
    if (!isLoggedIn()) {
      throw Exception('User must be logged in to like a post');
    }

    final userId = getCurrentUserId();

    // Check local cache first for offline handling
    final postIndex = _posts.indexWhere((post) => post.id == postId);
    if (postIndex != -1) {
      final post = _posts[postIndex];

      // Check if user already liked this post
      if (post.likedBy.contains(userId)) {
        return LikeResult.alreadyLiked;
      }

      // Update local cache immediately for responsive UI
      final updatedLikedBy = {...post.likedBy, userId};
      _posts[postIndex] = post.copyWith(
        likes: post.likes + 1,
        likedBy: updatedLikedBy,
      );
    }

    // Try to update Realtime Database
    try {
      await _realtimeDB.likePost(postId, userId);
      debugPrint('Post liked successfully in Realtime Database');
      return LikeResult.success;
    } catch (e) {
      debugPrint('Error liking post: $e');
      return LikeResult.success; // Return success since local update was done
    }
  }

  Future<bool> hasUserLikedPost(String postId) async {
    final userId = getCurrentUserId();

    // Check local cache first
    final postIndex = _posts.indexWhere((post) => post.id == postId);
    if (postIndex != -1) {
      return _posts[postIndex].likedBy.contains(userId);
    }

    return false;
  }

  Future<void> deletePost(String postId) async {
    if (!isLoggedIn()) {
      throw Exception('User must be logged in to delete a post');
    }

    final userId = getCurrentUserId();
    final postIndex = _posts.indexWhere((post) => post.id == postId);

    if (postIndex == -1) {
      throw Exception('Post not found');
    }

    final post = _posts[postIndex];
    if (post.authorId != userId) {
      throw Exception('You can only delete your own posts');
    }

    try {
      // Delete from Realtime Database
      await _realtimeDB.deletePost(postId);
      debugPrint('Post deleted successfully from Realtime Database');
    } catch (e) {
      debugPrint('Error deleting post from Realtime Database: $e');
      // Continue with local deletion even if cloud deletion fails
    }

    // Remove from local cache
    _posts.removeAt(postIndex);

    // Also delete associated replies
    _replies.removeWhere((reply) => reply.postId == postId);
  }

  Future<Post> updatePost(String postId, String newContent) async {
    if (!isLoggedIn()) {
      throw Exception('User must be logged in to edit a post');
    }

    final userId = getCurrentUserId();
    final postIndex = _posts.indexWhere((post) => post.id == postId);

    if (postIndex == -1) {
      throw Exception('Post not found');
    }

    final post = _posts[postIndex];
    if (post.authorId != userId) {
      throw Exception('You can only edit your own posts');
    }

    // Update local cache
    final updatedPost = post.copyWith(content: newContent);
    _posts[postIndex] = updatedPost;

    try {
      // Update in Realtime Database
      await _realtimeDB.updatePost(postId, newContent);
      debugPrint('Post updated successfully in Realtime Database');
    } catch (e) {
      debugPrint('Error updating post in Realtime Database: $e');
      // Continue with local update even if cloud update fails
    }

    return updatedPost;
  }

  Future<void> likeReply(String replyId) async {
    if (!isLoggedIn()) {
      throw Exception('User must be logged in to like a reply');
    }

    try {
      // Update likes in Realtime Database
      await _realtimeDB.likeReply(replyId);

      // Update local cache
      final replyIndex = _replies.indexWhere((reply) => reply.id == replyId);
      if (replyIndex != -1) {
        final reply = _replies[replyIndex];
        _replies[replyIndex] = reply.copyWith(likes: reply.likes + 1);
      }
    } catch (e) {
      debugPrint('Error liking reply: $e');

      // Update local cache anyway for responsive UI
      final replyIndex = _replies.indexWhere((reply) => reply.id == replyId);
      if (replyIndex != -1) {
        final reply = _replies[replyIndex];
        _replies[replyIndex] = reply.copyWith(likes: reply.likes + 1);
      }
    }
  }
}
