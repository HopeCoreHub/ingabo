import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class OfflineService {
  // Cache keys
  static const String _forumPostsKey = 'offline_forum_posts';
  static const String _userProfileKey = 'offline_user_profile';
  static const String _resourcesKey = 'offline_resources';
  
  // Check if device is online
  Future<bool> isOnline() async {
    final connectivityResults = await Connectivity().checkConnectivity();
    return !connectivityResults.contains(ConnectivityResult.none);
  }
  
  // Cache forum posts
  Future<void> cacheForumPosts(List<Map<String, dynamic>> posts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(posts);
      await prefs.setString(_forumPostsKey, jsonString);
    } catch (e) {
      debugPrint('Error caching forum posts: $e');
    }
  }
  
  // Get cached forum posts
  Future<List<Map<String, dynamic>>> getCachedForumPosts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_forumPostsKey);
      
      if (jsonString == null) {
        return [];
      }
      
      final List<dynamic> decodedList = jsonDecode(jsonString);
      return decodedList.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error getting cached forum posts: $e');
      return [];
    }
  }
  
  // Cache user profile
  Future<void> cacheUserProfile(Map<String, dynamic> profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(profile);
      await prefs.setString(_userProfileKey, jsonString);
    } catch (e) {
      debugPrint('Error caching user profile: $e');
    }
  }
  
  // Get cached user profile
  Future<Map<String, dynamic>?> getCachedUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_userProfileKey);
      
      if (jsonString == null) {
        return null;
      }
      
      final Map<String, dynamic> decodedMap = jsonDecode(jsonString);
      return decodedMap;
    } catch (e) {
      debugPrint('Error getting cached user profile: $e');
      return null;
    }
  }
  
  // Cache resources
  Future<void> cacheResources(Map<String, dynamic> resources) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(resources);
      await prefs.setString(_resourcesKey, jsonString);
    } catch (e) {
      debugPrint('Error caching resources: $e');
    }
  }
  
  // Get cached resources
  Future<Map<String, dynamic>> getCachedResources() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_resourcesKey);
      
      if (jsonString == null) {
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
      await prefs.remove(_userProfileKey);
      await prefs.remove(_resourcesKey);
    } catch (e) {
      debugPrint('Error clearing cache: $e');
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