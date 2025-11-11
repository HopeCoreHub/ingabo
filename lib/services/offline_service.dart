import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class OfflineService {
  // Cache keys
  static const String _forumPostsKey = 'offline_forum_posts';
  static const String _userProfileKey = 'offline_user_profile';
  static const String _resourcesKey = 'offline_resources';

  // Cache timestamp keys
  static const String _forumPostsTimestampKey = 'offline_forum_posts_timestamp';
  static const String _userProfileTimestampKey = 'offline_user_profile_timestamp';
  static const String _resourcesTimestampKey = 'offline_resources_timestamp';
  
  // TTL in hours (default: 24 hours)
  static const int _defaultTtlHours = 24;

  // Check if device is online
  Future<bool> isOnline() async {
    final connectivityResults = await Connectivity().checkConnectivity();
    return !connectivityResults.contains(ConnectivityResult.none);
  }

  // Cache forum posts with timestamp
  Future<void> cacheForumPosts(List<Map<String, dynamic>> posts, {int? ttlHours}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(posts);
      final timestamp = DateTime.now().toIso8601String();
      await prefs.setString(_forumPostsKey, jsonString);
      await prefs.setString(_forumPostsTimestampKey, timestamp);
    } catch (e) {
      debugPrint('Error caching forum posts: $e');
    }
  }

  // Get cached forum posts (returns empty if expired)
  Future<List<Map<String, dynamic>>> getCachedForumPosts({int? ttlHours}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_forumPostsKey);
      final timestampString = prefs.getString(_forumPostsTimestampKey);

      if (jsonString == null || timestampString == null) {
        return [];
      }

      // Check if cache is expired
      final timestamp = DateTime.parse(timestampString);
      final ttl = Duration(hours: ttlHours ?? _defaultTtlHours);
      final now = DateTime.now();
      
      if (now.difference(timestamp) > ttl) {
        // Cache expired, remove it
        await prefs.remove(_forumPostsKey);
        await prefs.remove(_forumPostsTimestampKey);
        debugPrint('Forum posts cache expired, removed');
        return [];
      }

      final List<dynamic> decodedList = jsonDecode(jsonString);
      return decodedList.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error getting cached forum posts: $e');
      return [];
    }
  }

  // Cache user profile with timestamp
  Future<void> cacheUserProfile(Map<String, dynamic> profile, {int? ttlHours}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(profile);
      final timestamp = DateTime.now().toIso8601String();
      await prefs.setString(_userProfileKey, jsonString);
      await prefs.setString(_userProfileTimestampKey, timestamp);
    } catch (e) {
      debugPrint('Error caching user profile: $e');
    }
  }

  // Get cached user profile (returns null if expired)
  Future<Map<String, dynamic>?> getCachedUserProfile({int? ttlHours}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_userProfileKey);
      final timestampString = prefs.getString(_userProfileTimestampKey);

      if (jsonString == null || timestampString == null) {
        return null;
      }

      // Check if cache is expired
      final timestamp = DateTime.parse(timestampString);
      final ttl = Duration(hours: ttlHours ?? _defaultTtlHours);
      final now = DateTime.now();
      
      if (now.difference(timestamp) > ttl) {
        // Cache expired, remove it
        await prefs.remove(_userProfileKey);
        await prefs.remove(_userProfileTimestampKey);
        debugPrint('User profile cache expired, removed');
        return null;
      }

      final Map<String, dynamic> decodedMap = jsonDecode(jsonString);
      return decodedMap;
    } catch (e) {
      debugPrint('Error getting cached user profile: $e');
      return null;
    }
  }

  // Cache resources with timestamp
  Future<void> cacheResources(Map<String, dynamic> resources, {int? ttlHours}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(resources);
      final timestamp = DateTime.now().toIso8601String();
      await prefs.setString(_resourcesKey, jsonString);
      await prefs.setString(_resourcesTimestampKey, timestamp);
    } catch (e) {
      debugPrint('Error caching resources: $e');
    }
  }

  // Get cached resources (returns empty if expired)
  Future<Map<String, dynamic>> getCachedResources({int? ttlHours}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_resourcesKey);
      final timestampString = prefs.getString(_resourcesTimestampKey);

      if (jsonString == null || timestampString == null) {
        return {};
      }

      // Check if cache is expired
      final timestamp = DateTime.parse(timestampString);
      final ttl = Duration(hours: ttlHours ?? _defaultTtlHours);
      final now = DateTime.now();
      
      if (now.difference(timestamp) > ttl) {
        // Cache expired, remove it
        await prefs.remove(_resourcesKey);
        await prefs.remove(_resourcesTimestampKey);
        debugPrint('Resources cache expired, removed');
        return {};
      }

      final Map<String, dynamic> decodedMap = jsonDecode(jsonString);
      return decodedMap;
    } catch (e) {
      debugPrint('Error getting cached resources: $e');
      return {};
    }
  }

  // Clear all cached data
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_forumPostsKey);
      await prefs.remove(_forumPostsTimestampKey);
      await prefs.remove(_userProfileKey);
      await prefs.remove(_userProfileTimestampKey);
      await prefs.remove(_resourcesKey);
      await prefs.remove(_resourcesTimestampKey);
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }
  
  // Clean up expired cache entries
  Future<void> cleanupExpiredCache() async {
    try {
      // Check and remove expired forum posts
      await getCachedForumPosts();
      
      // Check and remove expired user profile
      await getCachedUserProfile();
      
      // Check and remove expired resources
      await getCachedResources();
      
      debugPrint('Cache cleanup completed');
    } catch (e) {
      debugPrint('Error cleaning up expired cache: $e');
    }
  }

  // Cache specific data
  Future<void> cacheData(String key, dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(data);
      await prefs.setString('offline_$key', jsonString);
    } catch (e) {
      debugPrint('Error caching data for $key: $e');
    }
  }

  // Get cached specific data
  Future<dynamic> getCachedData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('offline_$key');

      if (jsonString == null) {
        return null;
      }

      return jsonDecode(jsonString);
    } catch (e) {
      debugPrint('Error getting cached data for $key: $e');
      return null;
    }
  }
}
