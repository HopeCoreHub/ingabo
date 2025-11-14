const functions = require('firebase-functions');
const admin = require('firebase-admin');
const fetch = require('node-fetch');

admin.initializeApp();

/**
 * Mahoro AI Chat Proxy Function
 * This function acts as a secure proxy between the app and Claude API
 * The API key is stored securely on the server, not in the app
 */
exports.mahoroChat = functions.https.onCall(async (data, context) => {
  // Log incoming request for debugging
  console.log('Mahoro function called');
  console.log('Data type:', typeof data);
  console.log('Data keys:', data ? Object.keys(data) : 'data is null/undefined');
  if (data) {
    const legacyData = data.data ? data.data : data;
    console.log('Inner keys:', legacyData ? Object.keys(legacyData) : []);
    console.log('Message length:', legacyData.message ? legacyData.message.length : 0);
    console.log('Has systemPrompt:', !!legacyData.systemPrompt);
    console.log('Conversation history length:', legacyData.conversationHistory ? legacyData.conversationHistory.length : 0);
  }

  // Support both callable payload shapes:
  // - Gen1 SDKs send { message, ... }
  // - Gen2 SDKs wrap payload under `.data`
  const requestData = data && typeof data === 'object' && 'data' in data ? data.data : data;
  console.log('Using request data keys:', requestData ? Object.keys(requestData) : 'no request data');

  // Optional: Verify user is authenticated (uncomment if you want to require login)
  // if (!context.auth) {
  //   throw new functions.https.HttpsError(
  //     'unauthenticated',
  //     'User must be authenticated to use Mahoro'
  //   );
  // }

  // Handle case where data might be null or undefined
  if (!requestData) {
    console.error('No data received in function call');
    throw new functions.https.HttpsError(
      'invalid-argument',
      'No data received. Please try again.'
    );
  }

  const { message, systemPrompt, conversationHistory } = requestData;

  // Validate input
  if (!message || typeof message !== 'string' || message.trim() === '') {
    console.error('Invalid message:', message, 'Type:', typeof message);
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Message is required and must be a non-empty string'
    );
  }

  // Get API key - for 2nd Gen functions, we need to use environment variables
  // Try environment variable first (works for 2nd gen)
  // Then try functions.config() as fallback (works for 1st gen)
  let apiKey = process.env.CLAUDE_API_KEY || process.env.claude_api_key;
  
  if (!apiKey) {
    try {
      const config = functions.config();
      if (config && config.claude && config.claude.api_key) {
        apiKey = config.claude.api_key;
        console.log('API key found in functions.config()');
      }
    } catch (error) {
      console.log('functions.config() not available:', error.message);
    }
  } else {
    console.log('API key found in environment variables');
  }
  
  if (!apiKey) {
    console.error('Claude API key not configured');
    console.error('Checked: process.env.CLAUDE_API_KEY, process.env.claude_api_key, functions.config().claude.api_key');
    throw new functions.https.HttpsError(
      'internal',
      'API key not configured. Please contact support.'
    );
  }
  
  console.log('API key successfully retrieved (length:', apiKey.length, ')');

  try {
    // Prepare messages array
    // If conversationHistory is provided, use it and append the new message
    // Otherwise, just use the new message
    let messages = [];
    if (conversationHistory && Array.isArray(conversationHistory) && conversationHistory.length > 0) {
      messages = [...conversationHistory];
    }
    // Add the current user message
    messages.push({
      role: 'user',
      content: message,
    });

    // Prepare request body for Claude API
    const requestBody = {
      model: 'claude-sonnet-4-20250514',
      max_tokens: 1024,
      system: systemPrompt || 'You are Mahoro, a supportive AI companion for mental health. Respond with empathy and care.',
      messages: messages,
    };

    // Make request to Claude API
    const response = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify(requestBody),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error('Claude API error:', response.status, errorText);
      
      if (response.status === 401) {
        throw new functions.https.HttpsError(
          'unauthenticated',
          'Invalid API key. Please contact support.'
        );
      } else if (response.status === 429) {
        throw new functions.https.HttpsError(
          'resource-exhausted',
          'Rate limit exceeded. Please wait a moment and try again.'
        );
      } else if (response.status >= 500) {
        throw new functions.https.HttpsError(
          'internal',
          'Claude API is temporarily unavailable. Please try again later.'
        );
      } else {
        throw new functions.https.HttpsError(
          'internal',
          `Claude API error: ${response.status}`
        );
      }
    }

    const responseData = await response.json();
    const content = responseData.content;
    
    if (content && content.length > 0 && content[0].text) {
      return { 
        response: content[0].text,
        model: responseData.model,
      };
    } else {
      console.error('Unexpected response format:', responseData);
      throw new functions.https.HttpsError(
        'internal',
        'No response from Claude API'
      );
    }
  } catch (error) {
    console.error('Error calling Claude API:', error);
    
    // If it's already an HttpsError, re-throw it
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    // Handle network errors
    if (error.message && error.message.includes('fetch')) {
      throw new functions.https.HttpsError(
        'internal',
        'Network error. Please check your internet connection and try again.'
      );
    }
    
    // Generic error
    throw new functions.https.HttpsError(
      'internal',
      'Failed to get response from Claude. Please try again.'
    );
  }
});

