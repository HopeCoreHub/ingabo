import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../firebase_options.dart';
import 'auth_service.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();

  factory FirebaseService() {
    return _instance;
  }

  FirebaseService._internal();

  // Firestore instance
  late final FirebaseFirestore _db;

  // Initialize Firebase
  static Future<void> initializeFirebase() async {
    try {
      debugPrint('Starting Firebase initialization...');

      // Check if Firebase is already initialized to avoid errors
      if (Firebase.apps.isEmpty) {
        final options = DefaultFirebaseOptions.currentPlatform;
        debugPrint('Initializing Firebase with options: ${options.projectId}');

        await Firebase.initializeApp(options: options);

        // Test Firebase connection
        try {
          final firestore = FirebaseFirestore.instance;
          await firestore.collection('test').doc('test').get();
          debugPrint('Firebase Firestore connection test successful');
        } catch (e) {
          debugPrint('Firebase Firestore connection test failed: $e');
        }

        debugPrint('Firebase initialized successfully');
      } else {
        debugPrint('Firebase was already initialized');
      }

      // Initialize instance variables after Firebase is initialized
      _instance._db = FirebaseFirestore.instance;
    } catch (e) {
      // Don't throw an exception, just log the error
      debugPrint('Error initializing Firebase: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      // Continue with app functionality even if Firebase fails to initialize
    }
  }

  // Save user data to Firestore
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    try {
      String userId = userData['id'];
      await _db.collection('users').doc(userId).set(userData);
      debugPrint('User data saved to Firestore');
    } catch (e) {
      debugPrint('Error saving user data to Firestore: $e');
      throw Exception('Error saving user data to Firestore: $e');
    }
  }

  // Save forum post to Firestore
  Future<void> saveForumPost(Map<String, dynamic> postData) async {
    try {
      String postId = postData['id'];
      await _db.collection('posts').doc(postId).set(postData);
      debugPrint('Forum post saved to Firestore');
    } catch (e) {
      debugPrint('Error saving forum post to Firestore: $e');
      throw Exception('Error saving forum post to Firestore: $e');
    }
  }

  // Save forum reply to Firestore
  Future<void> saveForumReply(Map<String, dynamic> replyData) async {
    try {
      String replyId = replyData['id'];
      await _db.collection('replies').doc(replyId).set(replyData);
      debugPrint('Forum reply saved to Firestore');
    } catch (e) {
      debugPrint('Error saving forum reply to Firestore: $e');
      throw Exception('Error saving forum reply to Firestore: $e');
    }
  }

  // Save Mahoro conversation to Firestore
  Future<void> saveMahoroConversation(
    String userId,
    Map<String, dynamic> conversationData,
  ) async {
    try {
      String convoId = conversationData['id'];
      await _db
          .collection('users')
          .doc(userId)
          .collection('mahoro_conversations')
          .doc(convoId)
          .set(conversationData);
      debugPrint('Mahoro conversation saved to Firestore');
    } catch (e) {
      debugPrint('Error saving Mahoro conversation to Firestore: $e');
      throw Exception('Error saving Mahoro conversation to Firestore: $e');
    }
  }

  // Save Muganga subscription to Firestore
  Future<void> saveMugangaSubscription(
    String userId,
    Map<String, dynamic> subscriptionData,
  ) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('muganga_subscriptions')
          .doc('current')
          .set(subscriptionData);
      debugPrint('Muganga subscription saved to Firestore');
    } catch (e) {
      debugPrint('Error saving Muganga subscription to Firestore: $e');
      throw Exception('Error saving Muganga subscription to Firestore: $e');
    }
  }

  // Save user settings to Firestore
  Future<void> saveUserSettings(
    String userId,
    Map<String, dynamic> settingsData,
  ) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('user_settings')
          .set(settingsData);
      debugPrint('User settings saved to Firestore');
    } catch (e) {
      debugPrint('Error saving user settings to Firestore: $e');
      throw Exception('Error saving user settings to Firestore: $e');
    }
  }

  // Migrate existing users from SharedPreferences to Firebase
  Future<void> migrateUsersToFirebase() async {
    try {
      // Get users from SharedPreferences
      final authService = AuthService();
      final users = await authService.getUsers();

      // Save each user to Firebase
      for (var user in users) {
        // Remove password before saving to Firebase
        // We'll handle authentication separately with Firebase Auth
        final userWithoutPassword = Map<String, dynamic>.from(user);
        userWithoutPassword.remove('password');

        await saveUserData(userWithoutPassword);
      }

      debugPrint('Users migrated to Firebase successfully');
    } catch (e) {
      debugPrint('Error migrating users to Firebase: $e');
      throw Exception('Error migrating users to Firebase: $e');
    }
  }

  // Create complete user data structure in Firebase
  Future<void> saveCompleteUserDataStructure(
    Map<String, dynamic> completeUserData,
  ) async {
    try {
      final usersList = completeUserData['users'] as List;

      for (var userData in usersList) {
        final user = userData as Map<String, dynamic>;
        final userId = user['id'] as String;

        // First save basic user data without nested objects
        final basicUserData = Map<String, dynamic>.from(user);
        basicUserData.remove('forum_activity');
        basicUserData.remove('mahoro_conversations');
        basicUserData.remove('muganga_subscription');
        basicUserData.remove('settings');
        basicUserData.remove('password'); // Don't store passwords in Firestore

        await saveUserData(basicUserData);

        // Save forum activity data
        if (user.containsKey('forum_activity')) {
          final forumActivity = user['forum_activity'] as Map<String, dynamic>;

          // Save posts
          if (forumActivity.containsKey('posts')) {
            final posts = forumActivity['posts'] as List;
            for (var post in posts) {
              await saveForumPost(post as Map<String, dynamic>);
            }
          }

          // Save replies
          if (forumActivity.containsKey('replies')) {
            final replies = forumActivity['replies'] as List;
            for (var reply in replies) {
              await saveForumReply(reply as Map<String, dynamic>);
            }
          }
        }

        // Save Mahoro conversations
        if (user.containsKey('mahoro_conversations')) {
          final conversations = user['mahoro_conversations'] as List;
          for (var conversation in conversations) {
            await saveMahoroConversation(
              userId,
              conversation as Map<String, dynamic>,
            );
          }
        }

        // Save Muganga subscription
        if (user.containsKey('muganga_subscription')) {
          await saveMugangaSubscription(
            userId,
            user['muganga_subscription'] as Map<String, dynamic>,
          );
        }

        // Save user settings
        if (user.containsKey('settings')) {
          await saveUserSettings(
            userId,
            user['settings'] as Map<String, dynamic>,
          );
        }
      }

      debugPrint('Complete user data structure saved to Firebase');
    } catch (e) {
      debugPrint('Error saving complete user data to Firebase: $e');
      throw Exception('Error saving complete user data to Firebase: $e');
    }
  }
}
