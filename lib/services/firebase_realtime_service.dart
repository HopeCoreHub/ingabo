import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/post_model.dart';
import '../models/reply_model.dart';

class FirebaseRealtimeService {
  static final FirebaseRealtimeService _instance =
      FirebaseRealtimeService._internal();
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // References
  late final DatabaseReference _postsRef;
  late final DatabaseReference _repliesRef;

  // Connection status
  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();
  Stream<bool> get connectionStatus => _connectionStatusController.stream;

  factory FirebaseRealtimeService() {
    return _instance;
  }

  FirebaseRealtimeService._internal() {
    _initDatabase();
  }

  void _initDatabase() {
    try {
      debugPrint('🔌 Initializing Firebase Realtime Database connection...');

      debugPrint('💾 Database URL configured from Firebase options');

      // Set database references
      _postsRef = _database.child('posts');
      _repliesRef = _database.child('replies');

      debugPrint('📂 Database paths initialized:');
      debugPrint('📂 Posts path: ${_postsRef.path}');
      debugPrint('📂 Replies path: ${_repliesRef.path}');

      try {
        // Set database persistence (offline capability)
        FirebaseDatabase.instance.setPersistenceEnabled(true);
        debugPrint('💾 Database persistence enabled');
      } catch (persistenceError) {
        // This might fail if called multiple times or after DB operations
        debugPrint('⚠️ Could not enable persistence: $persistenceError');
      }

      // Monitor connection state
      final connectedRef = FirebaseDatabase.instance.ref(".info/connected");
      connectedRef.onValue.listen((event) {
        final connected = event.snapshot.value as bool? ?? false;
        _isConnected = connected;
        _connectionStatusController.add(connected);
        debugPrint(
          connected
              ? '📶 Realtime DB connected'
              : '📵 Realtime DB disconnected',
        );

        // If connection is established, test database access
        if (connected) {
          _testDatabaseAccess();
        }
      });
    } catch (e) {
      debugPrint('❌ Error initializing Firebase Realtime Database: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
    }
  }

  // Test if we can actually read/write to the database
  Future<void> _testDatabaseAccess() async {
    try {
      debugPrint('🧪 Testing database access...');

      // Try to write a test value
      final testRef = _database.child('_test_connection');
      await testRef.set({'timestamp': ServerValue.timestamp});

      // Try to read it back
      final snapshot = await testRef.get();
      if (snapshot.exists) {
        debugPrint('✅ Database write/read test successful');

        // Clean up test data
        await testRef.remove();
      } else {
        debugPrint('⚠️ Database test write succeeded but read failed');
      }
    } catch (e) {
      debugPrint('❌ Database access test failed: $e');
    }
  }

  // POSTS OPERATIONS

  // Get all forum posts
  Future<List<Post>> getAllPosts() async {
    try {
      final snapshot = await _postsRef.get();

      if (snapshot.exists) {
        final Map<dynamic, dynamic> postsMap =
            snapshot.value as Map<dynamic, dynamic>;
        final List<Post> posts = [];

        postsMap.forEach((key, value) {
          // Parse the post data
          final post = _parsePostData(
            key.toString(),
            value as Map<dynamic, dynamic>,
          );
          posts.add(post);
        });

        // Sort by date (newest first)
        posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        debugPrint('Retrieved ${posts.length} posts from Realtime Database');
        return posts;
      }

      debugPrint('No posts found in Realtime Database');
      return [];
    } catch (e) {
      debugPrint('Error getting posts from Realtime Database: $e');
      return [];
    }
  }

  // Add a new post
  Future<Post?> addPost(Post post) async {
    try {
      debugPrint('🚀 Attempting to add post to Realtime Database...');
      debugPrint('💡 Post ID: ${post.id}');
      debugPrint('💡 Database path: ${_postsRef.path}');

      final newPostRef = _postsRef.child(post.id);
      debugPrint('💡 Full post path: ${newPostRef.path}');

      // Convert the post to a JSON map
      final postData = _convertPostToMap(post);
      debugPrint('💡 Post data: $postData');

      // Save to Realtime Database
      await newPostRef.set(postData);

      // Verify the data was saved
      final checkSnapshot = await newPostRef.get();
      if (checkSnapshot.exists) {
        debugPrint('✅ Post verified as saved in database');
      } else {
        debugPrint('⚠️ Post appears not to be saved - snapshot does not exist');
      }

      debugPrint('✅ Post added to Realtime Database: ${post.id}');
      return post;
    } catch (e) {
      debugPrint('❌ Error adding post to Realtime Database: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  // Like a post
  Future<bool> likePost(String postId, String userId) async {
    try {
      // Get current post data
      final postSnapshot = await _postsRef.child(postId).get();

      if (postSnapshot.exists) {
        final postData = postSnapshot.value as Map<dynamic, dynamic>;

        // Check if user already liked the post
        List<String> likedBy = [];
        if (postData.containsKey('likedBy')) {
          if (postData['likedBy'] is List) {
            likedBy = List<String>.from(postData['likedBy'] as List);
          } else if (postData['likedBy'] is Map) {
            // Handle map-style lists in Realtime DB
            final likedByMap = postData['likedBy'] as Map;
            likedBy = likedByMap.values.cast<String>().toList();
          }
        }

        if (likedBy.contains(userId)) {
          debugPrint('User $userId already liked post $postId');
          return false;
        }

        // Update likes count and likedBy list
        likedBy.add(userId);
        final int currentLikes = (postData['likes'] as int?) ?? 0;

        await _postsRef.child(postId).update({
          'likes': currentLikes + 1,
          'likedBy': likedBy,
        });

        debugPrint('Post $postId liked by user $userId');
        return true;
      }

      debugPrint('Post $postId not found');
      return false;
    } catch (e) {
      debugPrint('Error liking post in Realtime Database: $e');
      return false;
    }
  }

  // Like a reply
  Future<bool> likeReply(String replyId) async {
    try {
      // Get current reply data
      final replySnapshot = await _repliesRef.child(replyId).get();

      if (replySnapshot.exists) {
        final replyData = replySnapshot.value as Map<dynamic, dynamic>;
        final int currentLikes = (replyData['likes'] as int?) ?? 0;

        // Update likes count
        await _repliesRef.child(replyId).update({'likes': currentLikes + 1});

        debugPrint('Reply $replyId liked successfully');
        return true;
      }

      debugPrint('Reply $replyId not found');
      return false;
    } catch (e) {
      debugPrint('Error liking reply in Realtime Database: $e');
      return false;
    }
  }

  // REPLIES OPERATIONS

  // Get replies for a post
  Future<List<Reply>> getRepliesForPost(String postId) async {
    try {
      // Query replies by postId
      final query = _repliesRef.orderByChild('postId').equalTo(postId);
      final snapshot = await query.get();

      if (snapshot.exists) {
        final Map<dynamic, dynamic> repliesMap =
            snapshot.value as Map<dynamic, dynamic>;
        final List<Reply> replies = [];

        repliesMap.forEach((key, value) {
          final reply = _parseReplyData(
            key.toString(),
            value as Map<dynamic, dynamic>,
          );
          replies.add(reply);
        });

        // Sort by date (newest first)
        replies.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        debugPrint('Retrieved ${replies.length} replies for post $postId');
        return replies;
      }

      debugPrint('No replies found for post $postId');
      return [];
    } catch (e) {
      debugPrint('Error getting replies from Realtime Database: $e');
      return [];
    }
  }

  // Add a new reply
  Future<Reply?> addReply(Reply reply) async {
    try {
      final newReplyRef = _repliesRef.child(reply.id);

      // Convert the reply to a JSON map
      final replyData = _convertReplyToMap(reply);

      // Save to Realtime Database
      await newReplyRef.set(replyData);

      // Update the post's replies list
      await _postsRef.child(reply.postId).child('replies').push().set(reply.id);

      debugPrint('Reply added to Realtime Database: ${reply.id}');
      return reply;
    } catch (e) {
      debugPrint('Error adding reply to Realtime Database: $e');
      return null;
    }
  }

  // HELPER METHODS

  // Parse post data from Realtime DB format to Post object
  Post _parsePostData(String id, Map<dynamic, dynamic> data) {
    // Extract likedBy set
    Set<String> likedBy = {};
    if (data.containsKey('likedBy')) {
      if (data['likedBy'] is List) {
        likedBy = Set<String>.from(data['likedBy'] as List);
      } else if (data['likedBy'] is Map) {
        // Handle map-style lists in Realtime DB
        final likedByMap = data['likedBy'] as Map;
        likedBy = likedByMap.values.cast<String>().toSet();
      }
    }

    // Extract replies list
    List<String> replies = [];
    if (data.containsKey('replies')) {
      if (data['replies'] is List) {
        replies = List<String>.from(data['replies'] as List);
      } else if (data['replies'] is Map) {
        // Handle map-style lists in Realtime DB
        final repliesMap = data['replies'] as Map;
        replies = repliesMap.values.cast<String>().toList();
      }
    }

    // Create Post object
    return Post(
      id: id,
      title: data['title'] as String,
      content: data['content'] as String,
      authorId: data['authorId'] as String,
      authorName: data['authorName'] as String,
      createdAt: DateTime.parse(data['createdAt'] as String),
      likes: (data['likes'] as int?) ?? 0,
      replies: replies,
      isAnonymous: (data['isAnonymous'] as bool?) ?? true,
      likedBy: likedBy,
    );
  }

  // Parse reply data from Realtime DB format to Reply object
  Reply _parseReplyData(String id, Map<dynamic, dynamic> data) {
    return Reply(
      id: id,
      postId: data['postId'] as String,
      content: data['content'] as String,
      authorId: data['authorId'] as String,
      authorName: data['authorName'] as String,
      createdAt: DateTime.parse(data['createdAt'] as String),
      likes: (data['likes'] as int?) ?? 0,
    );
  }

  // Convert Post object to Realtime DB format
  Map<String, dynamic> _convertPostToMap(Post post) {
    return {
      'title': post.title,
      'content': post.content,
      'authorId': post.authorId,
      'authorName': post.authorName,
      'createdAt': post.createdAt.toIso8601String(),
      'likes': post.likes,
      'replies': post.replies,
      'isAnonymous': post.isAnonymous,
      'likedBy': post.likedBy.toList(),
    };
  }

  // Convert Reply object to Realtime DB format
  Map<String, dynamic> _convertReplyToMap(Reply reply) {
    return {
      'postId': reply.postId,
      'content': reply.content,
      'authorId': reply.authorId,
      'authorName': reply.authorName,
      'createdAt': reply.createdAt.toIso8601String(),
      'likes': reply.likes,
    };
  }

  // Create sample posts in Realtime Database
  Future<void> createSamplePosts() async {
    try {
      // Check if there are any posts
      final snapshot = await _postsRef.get();
      if (snapshot.exists) {
        debugPrint(
          'Posts already exist in Realtime Database, skipping sample creation',
        );
        return;
      }

      final currentTime = DateTime.now();

      // Sample post 1
      final post1 = Post(
        id: 'sample-post-1',
        title: 'Welcome to the HopeCore Forum',
        content:
            'This is a safe space for sharing experiences and supporting each other. Feel free to join the conversation!',
        authorId: 'system',
        authorName: 'HopeCore Team',
        createdAt: currentTime.subtract(const Duration(days: 7)),
        likes: 15,
        likedBy: {'user1', 'user2', 'user3'},
      );

      // Sample post 2
      final post2 = Post(
        id: 'sample-post-2',
        title: 'Tips for Managing Anxiety',
        content:
            'I\'ve found that deep breathing exercises, regular physical activity, and limiting caffeine really help with anxiety. What works for you?',
        authorId: 'sample_user_1',
        authorName: 'Anonymous',
        createdAt: currentTime.subtract(const Duration(days: 5)),
        likes: 8,
        likedBy: {'user4', 'user5'},
      );

      // Sample post 3
      final post3 = Post(
        id: 'sample-post-3',
        title: 'Seeking Support for Difficult Times',
        content:
            'I\'m going through a really tough period right now. Has anyone used any of the support resources in the app and found them helpful?',
        authorId: 'sample_user_2',
        authorName: 'Anonymous',
        createdAt: currentTime.subtract(const Duration(days: 2)),
        likes: 12,
        likedBy: {'user6', 'user7', 'user8'},
      );

      // Add posts to Realtime Database
      await addPost(post1);
      await addPost(post2);
      await addPost(post3);

      // Sample reply 1
      final reply1 = Reply(
        id: 'sample-reply-1',
        postId: post2.id,
        content:
            'Meditation has been life-changing for me. I use the Calm app for guided sessions.',
        authorId: 'sample_user_3',
        authorName: 'Anonymous',
        createdAt: currentTime.subtract(const Duration(days: 3)),
        likes: 5,
      );

      // Sample reply 2
      final reply2 = Reply(
        id: 'sample-reply-2',
        postId: post3.id,
        content:
            'The Mahoro AI assistant helped me a lot when I needed someone to talk to at 2am. It\'s surprisingly good!',
        authorId: 'sample_user_4',
        authorName: 'Anonymous',
        createdAt: currentTime.subtract(const Duration(hours: 12)),
        likes: 7,
      );

      // Add replies to Realtime Database
      await addReply(reply1);
      await addReply(reply2);

      debugPrint('Sample posts and replies created in Realtime Database');
    } catch (e) {
      debugPrint('Error creating sample posts in Realtime Database: $e');
    }
  }

  // Close resources
  void dispose() {
    _connectionStatusController.close();
  }
}
