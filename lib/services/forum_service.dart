import 'dart:math';
import 'package:uuid/uuid.dart';
import '../models/post_model.dart';
import '../models/reply_model.dart';
import 'auth_service.dart';

// Define like result enum at the top level
enum LikeResult {
  success,
  alreadyLiked
}

class ForumService {
  static final ForumService _instance = ForumService._internal();
  final List<Post> _posts = [];
  final List<Reply> _replies = [];
  final uuid = const Uuid();
  AuthService? _authService;
  
  factory ForumService() {
    return _instance;
  }

  ForumService._internal() {
    // Add some sample posts
    _addSamplePosts();
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

  List<Post> getPosts() {
    // Return a sorted copy of posts (newest first)
    final sortedPosts = [..._posts];
    sortedPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sortedPosts;
  }

  List<Post> searchPosts(String query) {
    if (query.isEmpty) {
      return getPosts();
    }
    
    final lowercaseQuery = query.toLowerCase();
    return _posts.where((post) {
      return post.title.toLowerCase().contains(lowercaseQuery) || 
             post.content.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  Post addPost(String title, String content) {
    if (!isLoggedIn()) {
      throw Exception('User must be logged in to create a post');
    }
    
    final newPost = Post(
      id: uuid.v4(),
      title: title,
      content: content,
      authorId: getCurrentUserId(),
      authorName: getCurrentUsername(),
      createdAt: DateTime.now(),
      likes: 0,
      replies: [],
      isAnonymous: true,
    );
    
    _posts.add(newPost);
    return newPost;
  }

  List<Reply> getRepliesForPost(String postId) {
    final postReplies = _replies.where((reply) => reply.postId == postId).toList();
    postReplies.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return postReplies;
  }

  Reply addReply(String postId, String content) {
    if (!isLoggedIn()) {
      throw Exception('User must be logged in to reply to a post');
    }
    
    final newReply = Reply(
      id: uuid.v4(),
      postId: postId,
      content: content,
      authorId: getCurrentUserId(),
      authorName: getCurrentUsername(),
      createdAt: DateTime.now(),
    );
    
    _replies.add(newReply);
    
    // Update the post's replies list
    final postIndex = _posts.indexWhere((post) => post.id == postId);
    if (postIndex != -1) {
      final post = _posts[postIndex];
      final updatedReplies = [...post.replies, newReply.id];
      _posts[postIndex] = post.copyWith(replies: updatedReplies);
    }
    
    return newReply;
  }

  LikeResult likePost(String postId) {
    if (!isLoggedIn()) {
      throw Exception('User must be logged in to like a post');
    }
    
    final userId = getCurrentUserId();
    final postIndex = _posts.indexWhere((post) => post.id == postId);
    
    if (postIndex != -1) {
      final post = _posts[postIndex];
      
      // Check if user already liked this post
      if (post.likedBy.contains(userId)) {
        return LikeResult.alreadyLiked;
      }
      
      // Add user to likedBy set and increment likes count
      final updatedLikedBy = {...post.likedBy, userId};
      _posts[postIndex] = post.copyWith(
        likes: post.likes + 1,
        likedBy: updatedLikedBy,
      );
      
      return LikeResult.success;
    }
    
    return LikeResult.success; // Return success by default if post not found
  }

  bool hasUserLikedPost(String postId) {
    final userId = getCurrentUserId();
    final postIndex = _posts.indexWhere((post) => post.id == postId);
    
    if (postIndex != -1) {
      return _posts[postIndex].likedBy.contains(userId);
    }
    
    return false;
  }

  void likeReply(String replyId) {
    if (!isLoggedIn()) {
      throw Exception('User must be logged in to like a reply');
    }
    
    final replyIndex = _replies.indexWhere((reply) => reply.id == replyId);
    if (replyIndex != -1) {
      _replies[replyIndex].likes += 1;
    }
  }

  void _addSamplePosts() {
    final samplePost1 = Post(
      id: uuid.v4(),
      title: 'Welcome to the Forum',
      content: 'Hello everybody :) i hope that y\'all are taking care of yourselves.',
      authorId: 'sample_user_1',
      authorName: 'Anonymous',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      likedBy: {},
    );
    
    final samplePost2 = Post(
      id: uuid.v4(),
      title: 'Seeking advice',
      content: 'I\'ve been feeling overwhelmed lately with everything going on. Does anyone have tips for managing stress?',
      authorId: 'sample_user_2',
      authorName: 'Anonymous',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      likedBy: {},
    );
    
    _posts.add(samplePost1);
    _posts.add(samplePost2);
    
    // Add a reply to the second post
    final reply = Reply(
      id: uuid.v4(),
      postId: samplePost2.id,
      content: 'Taking short breaks and practicing mindfulness has really helped me. Hope you feel better soon!',
      authorId: 'sample_user_3',
      authorName: 'Anonymous',
      createdAt: DateTime.now().subtract(const Duration(hours: 12)),
    );
    
    _replies.add(reply);
    
    // Update the post's replies list
    final postIndex = _posts.indexWhere((post) => post.id == samplePost2.id);
    if (postIndex != -1) {
      final post = _posts[postIndex];
      _posts[postIndex] = post.copyWith(replies: [...post.replies, reply.id]);
    }
  }
} 