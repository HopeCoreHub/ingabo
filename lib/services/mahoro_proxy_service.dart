import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

/// Service to communicate with Firebase Cloud Function that proxies Claude API calls
/// This keeps the API key secure on the server
class MahoroProxyService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Get AI response from Mahoro via secure backend proxy
  /// 
  /// [message] - The user's message
  /// [systemPrompt] - System instructions for the AI
  /// [conversationHistory] - Previous messages in the conversation
  Future<String> getResponse({
    required String message,
    required String systemPrompt,
    List<Map<String, dynamic>>? conversationHistory,
  }) async {
    try {
      final callable = _functions.httpsCallable('mahoroChat');
      
      debugPrint('Calling mahoroChat Cloud Function...');
      
      final result = await callable.call({
        'message': message,
        'systemPrompt': systemPrompt,
        'conversationHistory': conversationHistory ?? [],
      });

      final response = result.data as Map<String, dynamic>;
      final responseText = response['response'] as String;
      
      debugPrint('Received response from Cloud Function (length: ${responseText.length})');
      
      return responseText;
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Cloud Function error: ${e.code} - ${e.message}');
      debugPrint('Details: ${e.details}');
      
      switch (e.code) {
        case 'unauthenticated':
          return 'Authentication error. Please contact support.';
        case 'resource-exhausted':
          return 'Too many requests. Please wait a moment and try again.';
        case 'internal':
          return 'Service temporarily unavailable. Please try again later.';
        case 'invalid-argument':
          return 'Invalid request. Please try again.';
        default:
          return 'An error occurred. Please try again.';
      }
    } catch (e) {
      debugPrint('Error calling Mahoro proxy: $e');
      return 'Failed to connect. Please check your internet connection.';
    }
  }
}

