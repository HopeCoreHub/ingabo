# Backend Proxy Setup Guide for Mahoro AI

## Overview
This guide shows you how to set up a secure backend proxy using Firebase Cloud Functions so that:
- ✅ Your Claude API key stays secure on the server
- ✅ All users can use Mahoro without entering any keys
- ✅ You can control and monitor API usage
- ✅ You can update the key without rebuilding the app

---

## Step 1: Install Prerequisites

### Install Node.js (if not already installed)
1. Go to: https://nodejs.org/
2. Download and install the LTS version
3. Verify installation:
   ```bash
   node --version
   npm --version
   ```

### Install Firebase CLI
```bash
npm install -g firebase-tools
```

### Login to Firebase
```bash
firebase login
```

---

## Step 2: Initialize Firebase Functions

In your project root directory (`/Users/jovan/Projects/ingabo`):

```bash
firebase init functions
```

When prompted:
- **Language**: JavaScript (or TypeScript if you prefer)
- **ESLint**: Yes
- **Install dependencies**: Yes

This will create a `functions/` directory.

---

## Step 3: Create the Cloud Function

Edit `functions/index.js` (or `functions/src/index.ts` if using TypeScript):

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const https = require('https');

admin.initializeApp();

exports.mahoroChat = functions.https.onCall(async (data, context) => {
  // Optional: Verify user is authenticated
  // if (!context.auth) {
  //   throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  // }

  const { message, systemPrompt, conversationHistory } = data;

  // Get API key from environment variable (set in Firebase Console)
  const apiKey = functions.config().claude?.api_key;
  
  if (!apiKey) {
    throw new functions.https.HttpsError(
      'internal',
      'API key not configured. Please contact support.'
    );
  }

  try {
    // Prepare request to Claude API
    const requestBody = JSON.stringify({
      model: 'claude-3-5-sonnet-20241022',
      max_tokens: 1024,
      system: systemPrompt || 'You are Mahoro, a supportive AI companion for mental health.',
      messages: conversationHistory || [
        {
          role: 'user',
          content: message,
        },
      ],
    });

    // Make request to Claude API
    const response = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: requestBody,
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error('Claude API error:', response.status, errorText);
      
      if (response.status === 401) {
        throw new functions.https.HttpsError('unauthenticated', 'Invalid API key');
      } else if (response.status === 429) {
        throw new functions.https.HttpsError('resource-exhausted', 'Rate limit exceeded');
      } else {
        throw new functions.https.HttpsError('internal', 'Claude API error');
      }
    }

    const responseData = await response.json();
    const content = responseData.content;
    
    if (content && content.length > 0) {
      return { response: content[0].text };
    } else {
      throw new functions.https.HttpsError('internal', 'No response from Claude');
    }
  } catch (error) {
    console.error('Error calling Claude API:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError('internal', 'Failed to get response from Claude');
  }
});
```

---

## Step 4: Install Required Dependencies

In the `functions/` directory:

```bash
cd functions
npm install node-fetch@2  # For making HTTP requests
cd ..
```

---

## Step 5: Set the API Key in Firebase

### Option A: Using Firebase CLI (Recommended)
```bash
firebase functions:config:set claude.api_key="sk-ant-your-actual-api-key-here"
```

### Option B: Using Firebase Console
1. Go to: https://console.firebase.google.com/
2. Select your project: `hopecore-hub`
3. Go to: Functions → Configuration
4. Add environment variable:
   - Key: `claude.api_key`
   - Value: `sk-ant-your-actual-api-key-here`

---

## Step 6: Deploy the Function

```bash
firebase deploy --only functions
```

This will create a URL like:
`https://us-central1-hopecore-hub.cloudfunctions.net/mahoroChat`

---

## Step 7: Update Your Flutter App

### Add Cloud Functions dependency

In `pubspec.yaml`, add:
```yaml
dependencies:
  cloud_functions: ^5.1.5
```

Then run:
```bash
flutter pub get
```

### Create a new service file

Create `lib/services/mahoro_proxy_service.dart`:

```dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

class MahoroProxyService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<String> getResponse({
    required String message,
    required String systemPrompt,
    List<Map<String, dynamic>>? conversationHistory,
  }) async {
    try {
      final callable = _functions.httpsCallable('mahoroChat');
      
      final result = await callable.call({
        'message': message,
        'systemPrompt': systemPrompt,
        'conversationHistory': conversationHistory,
      });

      final response = result.data as Map<String, dynamic>;
      return response['response'] as String;
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Cloud Function error: ${e.code} - ${e.message}');
      
      switch (e.code) {
        case 'unauthenticated':
          return 'Authentication error. Please contact support.';
        case 'resource-exhausted':
          return 'Too many requests. Please wait a moment and try again.';
        case 'internal':
          return 'Service temporarily unavailable. Please try again later.';
        default:
          return 'An error occurred. Please try again.';
      }
    } catch (e) {
      debugPrint('Error calling Mahoro proxy: $e');
      return 'Failed to connect. Please check your internet connection.';
    }
  }
}
```

### Update mahoro_page.dart

Replace the `_getAnthropicResponse` method to use the proxy:

```dart
Future<String> _getAnthropicResponse(String userMessage) async {
  try {
    // Prepare system prompt based on language
    String systemPrompt = "You are Mahoro, a supportive AI companion for mental health. ";
    
    switch (_currentLanguage) {
      case 'EN':
        systemPrompt += "Respond in English with empathy and care. Keep responses concise and helpful.";
        break;
      case 'RW':
        systemPrompt += "Respond in Kinyarwanda with empathy and care. Your name 'Mahoro' means 'peace' in Kinyarwanda. Keep responses concise and helpful.";
        break;
      case 'FR':
        systemPrompt += "Réponds en français avec empathie et bienveillance. Garde tes réponses concises et utiles.";
        break;
      case 'SW':
        systemPrompt += "Jibu kwa Kiswahili kwa huruma na utunzaji. Weka majibu mafupi na yenye manufaa.";
        break;
      default:
        systemPrompt += "Respond in English with empathy and care. Keep responses concise and helpful.";
    }

    // Use proxy service instead of direct API call
    final proxyService = MahoroProxyService();
    
    // Convert conversation history to the format expected by the function
    final history = _conversationHistory.map((msg) => {
      'role': msg['role'],
      'content': msg['content'],
    }).toList();

    final response = await proxyService.getResponse(
      message: userMessage,
      systemPrompt: systemPrompt,
      conversationHistory: history,
    );

    return response;
  } catch (e) {
    debugPrint('Error getting Mahoro response: $e');
    final baseMessage = AppLocalizations.of(context).translate('imSorryIEncounteredAnError');
    final emergencyGuidance = AppLocalizations.of(context).translate('ifInImmediateDangerCallEmergency');
    return '$baseMessage $emergencyGuidance';
  }
}
```

---

## Step 8: Remove API Key Management from Settings

Since the key is now on the server, you can:
1. Remove the "Claude API Key" option from Admin Controls in `settings_page.dart`
2. Remove the API key storage code from `auth_service.dart`
3. Remove the API key dialog from `mahoro_page.dart`

---

## Step 9: Test

1. Deploy the function: `firebase deploy --only functions`
2. Run your app: `flutter run`
3. Test Mahoro - it should work without any API key setup!

---

## Security Benefits

✅ **API key is never in the app** - Users can't extract it
✅ **Centralized control** - Update the key without rebuilding
✅ **Usage monitoring** - See logs in Firebase Console
✅ **Rate limiting** - Can add limits per user
✅ **Cost control** - Monitor and limit usage

---

## Troubleshooting

### Function not found
- Make sure you deployed: `firebase deploy --only functions`
- Check the function name matches in both places

### Authentication errors
- Verify API key is set: `firebase functions:config:get`
- Check the key format (should start with `sk-ant-`)

### CORS errors (if testing from web)
- Cloud Functions handle CORS automatically for callable functions

---

## Next Steps (Optional)

1. **Add rate limiting** - Limit requests per user per day
2. **Add usage tracking** - Log requests to Firestore
3. **Add caching** - Cache common responses
4. **Add user authentication** - Require login to use Mahoro

