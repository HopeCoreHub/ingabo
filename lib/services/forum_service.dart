import 'dart:math';
import 'package:uuid/uuid.dart';
import '../models/post_model.dart';
import '../models/reply_model.dart';
import 'auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Define like result enum at the top level
enum LikeResult {
  success,
  alreadyLiked
}

class ForumService {
  static final ForumService _instance = ForumService._internal();
  final List<Post> _posts = []; // Local cache of posts
  final List<Reply> _replies = []; // Local cache of replies
  final uuid = const Uuid();
  AuthService? _authService;
  
  // Firebase instance
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  factory ForumService() {
    return _instance;
  }

  ForumService._internal() {
    // Add some sample posts if needed or load from Firebase
    _loadPostsFromFirebase();
  }
  
  // Load posts from Firebase
  Future<void> _loadPostsFromFirebase() async {
    try {
      // Clear local cache
      _posts.clear();
      _replies.clear();
      
      // Get posts from Firestore
      final postsSnapshot = await _db.collection('posts').get();
      
      for (var doc in postsSnapshot.docs) {
        final postData = doc.data();
        _posts.add(Post.fromJson(postData));
      }
      
      // Get replies from Firestore
      final repliesSnapshot = await _db.collection('replies').get();
      
      for (var doc in repliesSnapshot.docs) {
        final replyData = doc.data();
        _replies.add(Reply.fromJson(replyData));
      }
      
      debugPrint('Loaded ${_posts.length} posts and ${_replies.length} replies from Firebase');
    } catch (e) {
      debugPrint('Error loading posts from Firebase: $e');
      // If Firebase fails, add sample posts as fallback
      _addSamplePosts();
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
    // Refresh posts from Firebase if needed
    if (_posts.isEmpty) {
      await _loadPostsFromFirebase();
    }
    
    // Return a sorted copy of posts (newest first)
    final sortedPosts = [..._posts];
    sortedPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sortedPosts;
  }

  Future<List<Post>> searchPosts(String query) async {
    if (query.isEmpty) {
      return getPosts();
    }
    
    final lowercaseQuery = query.toLowerCase();
    
    try {
      // Try to search in Firebase first
      final querySnapshot = await _db.collection('posts')
        .where('title', isGreaterThanOrEqualTo: lowercaseQuery)
        .where('title', isLessThanOrEqualTo: lowercaseQuery + '\uf8ff')
        .get();
        
      List<Post> results = querySnapshot.docs.map((doc) => Post.fromJson(doc.data())).toList();
      
      // Also search in content
      final contentQuerySnapshot = await _db.collection('posts')
        .where('content', isGreaterThanOrEqualTo: lowercaseQuery)
        .where('content', isLessThanOrEqualTo: lowercaseQuery + '\uf8ff')
        .get();
        
      // Add content results but avoid duplicates
      for (var doc in contentQuerySnapshot.docs) {
        final post = Post.fromJson(doc.data());
        if (!results.any((p) => p.id == post.id)) {
          results.add(post);
        }
      }
      
      return results;
    } catch (e) {
      debugPrint('Error searching posts in Firebase: $e');
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
    );
    
    try {
      // Save to Firebase
      await _db.collection('posts').doc(newPostId).set(newPost.toJson());
      
      // Add to local cache
      _posts.add(newPost);
      
      return newPost;
    } catch (e) {
      debugPrint('Error adding post to Firebase: $e');
      // Add to local cache anyway
      _posts.add(newPost);
      return newPost;
    }
  }

  Future<List<Reply>> getRepliesForPost(String postId) async {
    try {
      // Get replies from Firebase
      final querySnapshot = await _db.collection('replies')
        .where('postId', isEqualTo: postId)
        .get();
      
      final postReplies = querySnapshot.docs.map((doc) => Reply.fromJson(doc.data())).toList();
      
      // Update local cache
      for (var reply in postReplies) {
        final index = _replies.indexWhere((r) => r.id == reply.id);
        if (index != -1) {
          _replies[index] = reply;
        } else {
          _replies.add(reply);
        }
      }
      
      // Sort replies (newest first)
      postReplies.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return postReplies;
    } catch (e) {
      debugPrint('Error getting replies from Firebase: $e');
      // Fall back to local cache
      final postReplies = _replies.where((reply) => reply.postId == postId).toList();
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
    );
    
    try {
      // Save to Firebase
      await _db.collection('replies').doc(newReplyId).set(newReply.toJson());
      
      // Add to local cache
      _replies.add(newReply);
      
      // Update the post's replies list in Firebase
      final postRef = _db.collection('posts').doc(postId);
      await _db.runTransaction((transaction) async {
        final postDoc = await transaction.get(postRef);
        if (postDoc.exists) {
          final post = Post.fromJson(postDoc.data()!);
          final updatedReplies = [...post.replies, newReply.id];
          transaction.update(postRef, {'replies': updatedReplies});
        }
      });
      
      // Update the post's replies list in local cache
      final postIndex = _posts.indexWhere((post) => post.id == postId);
      if (postIndex != -1) {
        final post = _posts[postIndex];
        final updatedReplies = [...post.replies, newReply.id];
        _posts[postIndex] = post.copyWith(replies: updatedReplies);
      }
      
      return newReply;
    } catch (e) {
      debugPrint('Error adding reply to Firebase: $e');
      
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
    
    try {
      // Check if user already liked this post in Firebase
      final postRef = _db.collection('posts').doc(postId);
      
      final result = await _db.runTransaction((transaction) async {
        final postDoc = await transaction.get(postRef);
        
        if (!postDoc.exists) {
          return LikeResult.success; // Post not found
        }
        
        final post = Post.fromJson(postDoc.data()!);
        
        // Check if user already liked this post
        if (post.likedBy.contains(userId)) {
          return LikeResult.alreadyLiked;
        }
        
        // Add user to likedBy set and increment likes count
        final updatedLikedBy = [...post.likedBy, userId];
        
        transaction.update(postRef, {
          'likes': post.likes + 1,
          'likedBy': updatedLikedBy,
        });
        
        return LikeResult.success;
      });
      
      // Update local cache
      final postIndex = _posts.indexWhere((post) => post.id == postId);
      if (postIndex != -1) {
        final post = _posts[postIndex];
        if (!post.likedBy.contains(userId)) {
          final updatedLikedBy = {...post.likedBy, userId};
          _posts[postIndex] = post.copyWith(
            likes: post.likes + 1,
            likedBy: updatedLikedBy,
          );
        }
      }
      
      return result;
    } catch (e) {
      debugPrint('Error liking post in Firebase: $e');
      
      // Fall back to local cache
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
      }
      
      return LikeResult.success;
    }
  }

  Future<bool> hasUserLikedPost(String postId) async {
    final userId = getCurrentUserId();
    
    try {
      // Check in Firebase
      final postDoc = await _db.collection('posts').doc(postId).get();
      
      if (postDoc.exists) {
        final post = Post.fromJson(postDoc.data()!);
        return post.likedBy.contains(userId);
      }
      
      return false;
    } catch (e) {
      debugPrint('Error checking if user liked post in Firebase: $e');
      
      // Fall back to local cache
      final postIndex = _posts.indexWhere((post) => post.id == postId);
      
      if (postIndex != -1) {
        return _posts[postIndex].likedBy.contains(userId);
      }
      
      return false;
    }
  }

  Future<void> likeReply(String replyId) async {
    if (!isLoggedIn()) {
      throw Exception('User must be logged in to like a reply');
    }
    
    try {
      // Update likes count in Firebase
      final replyRef = _db.collection('replies').doc(replyId);
      
      await _db.runTransaction((transaction) async {
        final replyDoc = await transaction.get(replyRef);
        
        if (replyDoc.exists) {
          final reply = Reply.fromJson(replyDoc.data()!);
          transaction.update(replyRef, {'likes': reply.likes + 1});
        }
      });
      
      // Update local cache
      final replyIndex = _replies.indexWhere((reply) => reply.id == replyId);
      if (replyIndex != -1) {
        _replies[replyIndex].likes += 1;
      }
    } catch (e) {
      debugPrint('Error liking reply in Firebase: $e');
      
      // Update local cache anyway
      final replyIndex = _replies.indexWhere((reply) => reply.id == replyId);
      if (replyIndex != -1) {
        _replies[replyIndex].likes += 1;
      }
    }
  }

  void _addSamplePosts() {
    if (_posts.isNotEmpty) return; // Don't add samples if we already have posts
    
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
    
    // Try to save sample data to Firebase
    _saveSampleDataToFirebase(samplePost1, samplePost2, reply);
  }
  
  Future<void> _saveSampleDataToFirebase(Post post1, Post post2, Reply reply) async {
    try {
      // Check if posts collection is empty before adding samples
      final postsCount = await _db.collection('posts').count().get();
      
      if (postsCount.count == 0) {
        // Save sample posts to Firebase
        await _db.collection('posts').doc(post1.id).set(post1.toJson());
        await _db.collection('posts').doc(post2.id).set(post2.toJson());
        
        // Save sample reply to Firebase
        await _db.collection('replies').doc(reply.id).set(reply.toJson());
        
        debugPrint('Saved sample data to Firebase');
      } else {
        debugPrint('Posts already exist in Firebase, skipping sample data creation');
      }
    } catch (e) {
      debugPrint('Error saving sample data to Firebase: $e');
      // Continue with local samples if Firebase fails
    }
  }
} 