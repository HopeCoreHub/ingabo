import 'package:flutter/material.dart';
import 'dart:math';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'accessibility_provider.dart';
import 'services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'localization/app_localizations.dart';
import 'localization/localized_text.dart';
import 'localization/base_screen.dart';
import 'services/content_reporting_service.dart';
import 'widgets/content_report_dialog.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class MahoroPage extends BaseScreen {
  const MahoroPage({super.key});

  @override
  State<MahoroPage> createState() => _MahoroPageState();
}

class _MahoroPageState extends BaseScreenState<MahoroPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  late AnimationController _typingAnimController;
  final List<ChatMessage> _messages = [
    ChatMessage(
      text:
          "Muraho! I'm Mahoro, your supportive AI companion. How can I help you today? You can speak to me in Kinyarwanda, English, Swahili, or French.",
      isUserMessage: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
    ),
  ];
  bool _isTyping = false;
  String _currentLanguage = 'EN';
  String _currentLanguageName = 'English';
  bool _isApiKeyValid = true;
  String _conversationId = '';

  // Firebase instance
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // AI service - supports both Gemini and Claude
  dynamic _aiService;
  String _currentApiProvider = 'gemini'; // 'gemini' or 'claude'

  final Map<String, String> _languageNames = {
    'EN': 'English',
    'RW': 'Kinyarwanda',
    'FR': 'Français',
    'SW': 'Swahili',
  };

  // Conversation history for API
  final List<Map<String, dynamic>> _conversationHistory = [
    {
      "role": "assistant",
      "content":
          "Muraho! I'm Mahoro, your supportive AI companion. How can I help you today? You can speak to me in Kinyarwanda, English, Swahili, or French.",
    },
  ];

  // Get Gemini API key
  Future<String?> _getGeminiApiKey() async {
    return await AuthService.getGeminiApiKey();
  }

  // Get Claude API key
  Future<String?> _getClaudeApiKey() async {
    return await AuthService.getApiKey();
  }

  @override
  void initState() {
    super.initState();
    _typingAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat();

    // Store API keys securely on first run
    _storeApiKeys();

    // Create a new conversation ID
    _createNewConversation();

    // Load previous conversation if any
    _loadPreviousConversation();

    // Initialize AI service (Gemini first, fallback to Claude)
    _initializeAIService();
  }

  Future<void> _createNewConversation() async {
    // Generate a unique ID for this conversation
    _conversationId = const Uuid().v4();
  }

  Future<void> _loadPreviousConversation() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      if (!authService.isLoggedIn || authService.userId == null) {
        return; // Can't load conversations if user is not logged in
      }

      final userId = authService.userId!;

      // Get the most recent conversation from Firebase
      final querySnapshot =
          await _db
              .collection('users')
              .doc(userId)
              .collection('mahoro_conversations')
              .orderBy('lastUpdated', descending: true)
              .limit(1)
              .get();

      if (querySnapshot.docs.isEmpty) {
        return; // No previous conversations
      }

      final conversationDoc = querySnapshot.docs.first;
      final conversationData = conversationDoc.data();

      // Update conversation ID
      _conversationId = conversationDoc.id;

      // Get the language preference
      if (conversationData.containsKey('language')) {
        final language = conversationData['language'] as String;
        setState(() {
          _currentLanguage = language;
          _currentLanguageName = _languageNames[language] ?? language;
        });
      }

      // Get messages
      if (conversationData.containsKey('messages')) {
        final messages = conversationData['messages'] as List<dynamic>;

        setState(() {
          // Clear existing messages and history
          _messages.clear();
          _conversationHistory.clear();

          for (var message in messages) {
            final role = message['role'] as String;
            final content = message['content'] as String;
            final timestamp = DateTime.parse(message['timestamp'] as String);

            // Add to UI messages
            _messages.add(
              ChatMessage(
                text: content,
                isUserMessage: role == 'user',
                timestamp: timestamp,
              ),
            );

            // Add to conversation history
            _conversationHistory.add({"role": role, "content": content});
          }
        });
      }

      debugPrint('Loaded previous conversation');
    } catch (e) {
      debugPrint('Error loading previous conversation: $e');
      // Continue with new conversation if loading fails
    }
  }

  Future<void> _saveConversation() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      if (!authService.isLoggedIn || authService.userId == null) {
        return; // Can't save if user is not logged in
      }

      final userId = authService.userId!;

      // Create a list of message data to save
      final List<Map<String, dynamic>> messagesData = [];

      for (var message in _messages) {
        messagesData.add({
          'role': message.isUserMessage ? 'user' : 'assistant',
          'content': message.text,
          'timestamp': message.timestamp.toIso8601String(),
        });
      }

      // Save to Firebase
      await _db
          .collection('users')
          .doc(userId)
          .collection('mahoro_conversations')
          .doc(_conversationId)
          .set({
            'id': _conversationId,
            'language': _currentLanguage,
            'messages': messagesData,
            'lastUpdated': DateTime.now().toIso8601String(),
          }, SetOptions(merge: true));

      debugPrint('Saved conversation to Firebase');
    } catch (e) {
      debugPrint('Error saving conversation to Firebase: $e');
      // Continue even if saving fails
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _typingAnimController.dispose();
    super.dispose();
  }

  Future<void> _storeApiKeys() async {
    // Check if we have Gemini API key
    final geminiKey = await _getGeminiApiKey();
    if (geminiKey == null || geminiKey.isEmpty) {
      debugPrint("No Gemini API key found. Will try Claude API.");
    } else {
      debugPrint(
        "Using existing Gemini API key: ${geminiKey.substring(0, 10)}... (length: ${geminiKey.length})",
      );
    }

    // Check if we have Claude API key
    final claudeKey = await _getClaudeApiKey();
    if (claudeKey == null || claudeKey.isEmpty) {
      // Store the Claude API key securely as fallback
      final apiKey =
          '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';
      debugPrint(
        "Storing Claude API key as fallback: ${apiKey.substring(0, 10)}... (length: ${apiKey.length})",
      );
      await AuthService.storeApiKey(apiKey);
    } else {
      debugPrint(
        "Using existing Claude API key: ${claudeKey.substring(0, 10)}... (length: ${claudeKey.length})",
      );
    }
  }

  Future<void> _initializeAIService() async {
    // Try Gemini first
    final geminiKey = await _getGeminiApiKey();
    if (geminiKey != null && geminiKey.isNotEmpty) {
      try {
        _aiService = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: geminiKey,
        );
        _currentApiProvider = 'gemini';
        debugPrint("Initialized Gemini AI service");
        return;
      } catch (e) {
        debugPrint("Failed to initialize Gemini: $e");
      }
    }

    // Fallback to Claude
    final claudeKey = await _getClaudeApiKey();
    if (claudeKey != null && claudeKey.isNotEmpty) {
      _aiService = ClaudeService(apiKey: claudeKey);
      _currentApiProvider = 'claude';
      debugPrint("Initialized Claude AI service");
    } else {
      debugPrint("No API keys available");
    }
  }

  void _setLanguage(String langCode) {
    setState(() {
      _currentLanguage = langCode;
      _currentLanguageName = _languageNames[langCode] ?? langCode;
    });

    // Save language preference to the current conversation
    _saveConversation();
  }

  void _addMessage(String text, bool isUserMessage) {
    setState(() {
      _messages.add(
        ChatMessage(
          text: text,
          isUserMessage: isUserMessage,
          timestamp: DateTime.now(),
        ),
      );

      // Add to conversation history for API
      _conversationHistory.add({
        "role": isUserMessage ? "user" : "assistant",
        "content": text,
      });
    });

    // Save to Firebase
    _saveConversation();
  }

  Future<String> _getAIResponse(String userMessage) async {
    try {
      // Prepare system prompt based on language
      String systemPrompt =
          "You are Mahoro, a supportive AI companion for mental health. ";

      switch (_currentLanguage) {
        case 'EN':
          systemPrompt +=
              "Respond in English with empathy and care. Keep responses concise and helpful.";
          break;
        case 'RW':
          systemPrompt +=
              "Respond in Kinyarwanda with empathy and care. Your name 'Mahoro' means 'peace' in Kinyarwanda. Keep responses concise and helpful.";
          break;
        case 'FR':
          systemPrompt +=
              "Réponds en français avec empathie et bienveillance. Garde tes réponses concises et utiles.";
          break;
        case 'SW':
          systemPrompt +=
              "Jibu kwa Kiswahili kwa huruma na utunzaji. Weka majibu mafupi na yenye manufaa.";
          break;
        default:
          systemPrompt +=
              "Respond in English with empathy and care. Keep responses concise and helpful.";
      }

      // Try Gemini first
      if (_currentApiProvider == 'gemini' && _aiService is GenerativeModel) {
        try {
          debugPrint("Making API request to Gemini...");
          final model = _aiService as GenerativeModel;
          
          final prompt = '$systemPrompt\n\nUser: $userMessage\n\nMahoro:';
          final content = [Content.text(prompt)];
          final response = await model.generateContent(content);
          
          final text = response.text;
          if (text != null && text.isNotEmpty) {
            debugPrint("Received response from Gemini");
            return text;
          } else {
            throw Exception('Empty response from Gemini');
          }
        } catch (e) {
          debugPrint('Gemini API Error: $e');
          // Fallback to Claude if Gemini fails
          debugPrint("Falling back to Claude API...");
          await _fallbackToClaude();
          return await _getAIResponse(userMessage); // Retry with Claude
        }
      }

      // Use Claude
      if (_currentApiProvider == 'claude' && _aiService is ClaudeService) {
        try {
          debugPrint("Making API request to Claude...");
          final claudeService = _aiService as ClaudeService;

          // Generate response using Claude
          final response = await claudeService.generateContent(
            prompt: userMessage,
            systemInstructions: systemPrompt,
          );

          debugPrint("Received response from Claude");
          return response;
        } catch (e) {
          debugPrint('Claude API Error: $e');
          if (e.toString().contains('authentication') || e.toString().contains('401')) {
            setState(() {
              _isApiKeyValid = false;
            });
            return "I'm having trouble with authentication. Please contact support.";
          } else {
            return "I'm having trouble connecting right now. Please try again later.";
          }
        }
      }

      // No API service available
      setState(() {
        _isApiKeyValid = false;
      });
      return "API key not found. Please contact support.";
    } catch (e) {
      debugPrint('Exception: $e');
      return "I'm sorry, I encountered an error. Please try again.";
    }
  }

  Future<void> _fallbackToClaude() async {
    final claudeKey = await _getClaudeApiKey();
    if (claudeKey != null && claudeKey.isNotEmpty) {
      _aiService = ClaudeService(apiKey: claudeKey);
      _currentApiProvider = 'claude';
      debugPrint("Switched to Claude API");
    }
  }

  void _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;

    _messageController.clear();
    _addMessage(text, true);

    // Show typing indicator
    setState(() {
      _isTyping = true;
    });

    try {
      // Get response from AI (Gemini or Claude)
      final response = await _getAIResponse(text);

      if (mounted) {
        setState(() {
          _isTyping = false;
        });

        _addMessage(response, false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTyping = false;
        });

        _addMessage(
          "I'm sorry, I encountered an error. Please try again.",
          false,
        );
      }
    }
  }

  @override
  Widget buildScreen(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final highContrastMode = accessibilityProvider.highContrastMode;

    return Scaffold(
      backgroundColor:
          (highContrastMode && isDarkMode)
              ? Colors.black
              : (isDarkMode ? Colors.black : Colors.white),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildLanguageStatus(),
            Expanded(child: _buildChatList()),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final highContrastMode = accessibilityProvider.highContrastMode;
    final accentColor = const Color(0xFF8A4FFF); // Use purple for both modes

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
            highContrastMode
                ? (isDarkMode ? Colors.black : Colors.white)
                : accentColor,
        borderRadius: BorderRadius.circular(14),
        border:
            highContrastMode
                ? Border.all(
                  color: isDarkMode ? Colors.white : Colors.black,
                  width: 2.0,
                )
                : null,
        boxShadow:
            highContrastMode
                ? null
                : [
                  BoxShadow(
                    color: accentColor.withAlpha(63),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color:
                      highContrastMode
                          ? (isDarkMode
                              ? Colors.white.withAlpha(51)
                              : Colors.black.withAlpha(51))
                          : Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.psychology_rounded,
                  color:
                      highContrastMode
                          ? (isDarkMode ? Colors.white : Colors.black)
                          : Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LocalizedText(
                    'mahoro',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color:
                          highContrastMode
                              ? (isDarkMode ? Colors.white : Colors.black)
                              : Colors.white,
                    ),
                  ),
                  LocalizedText(
                    'yourSupportCompanion',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          highContrastMode
                              ? (isDarkMode ? Colors.white : Colors.black87)
                              : Colors.white,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildLanguageButton('EN', accentColor),
              _buildLanguageButton('RW', accentColor),
              _buildLanguageButton('FR', accentColor),
              _buildLanguageButton('SW', accentColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageButton(String langCode, Color accentColor) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final highContrastMode = accessibilityProvider.highContrastMode;
    final isSelected = _currentLanguage == langCode;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => _setLanguage(langCode),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                highContrastMode
                    ? (isSelected
                        ? (isDarkMode ? Colors.white : Colors.black)
                        : (isDarkMode
                            ? Colors.white.withAlpha(76)
                            : Colors.black.withAlpha(76)))
                    : (isSelected ? Colors.white : Colors.white.withAlpha(76)),
            border:
                highContrastMode && isSelected
                    ? Border.all(
                      color: isDarkMode ? Colors.black : Colors.white,
                      width: 2.0,
                    )
                    : null,
          ),
          child: Center(
            child: Text(
              langCode,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color:
                    highContrastMode
                        ? (isSelected
                            ? (isDarkMode ? Colors.black : Colors.white)
                            : (isDarkMode ? Colors.white : Colors.black))
                        : (isSelected ? accentColor : Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageStatus() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final highContrastMode = accessibilityProvider.highContrastMode;
    final accentColor = const Color(0xFF8A4FFF); // Use purple for both modes

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      highContrastMode
                          ? (isDarkMode
                              ? Colors.white.withAlpha(76)
                              : Colors.black.withAlpha(76))
                          : accentColor.withAlpha(76),
                ),
                child: Icon(
                  Icons.smart_toy_outlined,
                  color:
                      highContrastMode
                          ? (isDarkMode ? Colors.white : Colors.black)
                          : accentColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _currentLanguageName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color:
                          highContrastMode
                              ? (isDarkMode ? Colors.white : Colors.black)
                              : (isDarkMode ? Colors.white : Colors.black87),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isApiKeyValid ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isApiKeyValid
                            ? 'AI Support Active'
                            : 'API Connection Error',
                        style: TextStyle(
                          fontSize: 10,
                          color:
                              highContrastMode
                                  ? (isDarkMode
                                      ? Colors.white70
                                      : Colors.black87)
                                  : (isDarkMode
                                      ? Colors.white60
                                      : Colors.black54),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final highContrastMode = accessibilityProvider.highContrastMode;
    final accentColor = const Color(0xFF8A4FFF); // Use purple for both modes

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      reverse: true,
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (_isTyping && index == 0) {
          return _buildTypingIndicator(
            accentColor,
            highContrastMode,
            isDarkMode,
          );
        }

        final adjustedIndex = _isTyping ? index - 1 : index;
        final message = _messages[_messages.length - 1 - adjustedIndex];
        return _buildChatBubble(
          message,
          accentColor,
          highContrastMode,
          isDarkMode,
        );
      },
    );
  }

  Widget _buildTypingIndicator(
    Color accentColor,
    bool highContrastMode,
    bool isDarkMode,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  highContrastMode
                      ? (isDarkMode ? Colors.white : Colors.black)
                      : accentColor,
            ),
            child: Icon(
              Icons.smart_toy_outlined,
              color:
                  highContrastMode
                      ? (isDarkMode ? Colors.black : Colors.white)
                      : Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              color:
                  highContrastMode
                      ? (isDarkMode
                          ? Colors.white.withAlpha(178)
                          : Colors.black.withAlpha(178))
                      : accentColor.withAlpha(178),
            ),
            child: AnimatedBuilder(
              animation: _typingAnimController,
              builder: (context, child) {
                return Row(
                  children: List.generate(3, (i) {
                    final delay = i * 0.3;
                    final sinValue = sin(
                      (_typingAnimController.value * 2 * pi) + delay,
                    );
                    final size = 6.0 + (sinValue + 1) * 2.0;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            highContrastMode
                                ? (isDarkMode ? Colors.black : Colors.white)
                                : Colors.white,
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(
    ChatMessage message,
    Color accentColor,
    bool highContrastMode,
    bool isDarkMode,
  ) {
    final alignment =
        message.isUserMessage
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start;

    final bubbleColor =
        highContrastMode
            ? (message.isUserMessage
                ? (isDarkMode ? Colors.white : Colors.black)
                : (isDarkMode ? Colors.black : Colors.white))
            : (message.isUserMessage
                ? (isDarkMode ? const Color(0xFF1E293B) : Colors.grey.shade200)
                : (isDarkMode 
                    ? Colors.white.withAlpha(25)  // Translucent white in dark mode
                    : Colors.white.withAlpha(204)));  // Translucent white in light mode

    final textColor =
        highContrastMode
            ? (message.isUserMessage
                ? (isDarkMode ? Colors.black : Colors.white)
                : (isDarkMode ? Colors.white : Colors.black))
            : (message.isUserMessage
                ? (isDarkMode ? Colors.white : Colors.black87)
                : (isDarkMode ? Colors.white : Colors.black87));  // Dark text on translucent white

    final radius =
        message.isUserMessage
            ? const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            )
            : const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomRight: Radius.circular(16),
            );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            message.isUserMessage
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
        children: [
          if (!message.isUserMessage) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    highContrastMode
                        ? (isDarkMode ? Colors.white : Colors.black)
                        : accentColor,
              ),
              child: Icon(
                Icons.psychology_rounded,
                color:
                    highContrastMode
                        ? (isDarkMode ? Colors.black : Colors.white)
                        : Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 6),
          ],

          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            child: Column(
              crossAxisAlignment: alignment,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    color: bubbleColor,
                    border:
                        highContrastMode
                            ? Border.all(
                              color: isDarkMode ? Colors.white : Colors.black,
                              width: 1.0,
                            )
                            : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.text,
                        style: TextStyle(fontSize: 14, color: textColor),
                      ),
                      // Add report button for AI messages
                      if (!message.isUserMessage) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            InkWell(
                              onTap: () => _showReportDialog(message),
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.flag_outlined,
                                      size: 12,
                                      color: Colors.white.withValues(
                                        alpha: 153,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Report',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.white.withValues(
                                          alpha: 153,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    fontSize: 10,
                    color: isDarkMode ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ),
          ),

          if (message.isUserMessage) ...[
            const SizedBox(width: 6),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    highContrastMode
                        ? (isDarkMode ? Colors.white : Colors.black)
                        : (isDarkMode
                            ? const Color(0xFF1E293B)
                            : Colors.grey.shade200),
              ),
              child: Icon(
                Icons.person,
                color:
                    highContrastMode
                        ? (isDarkMode ? Colors.black : Colors.white)
                        : (isDarkMode ? Colors.white : Colors.black87),
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final accentColor = const Color(0xFF8A4FFF); // Use purple for both modes

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  maxLines: 5,
                  minLines: 1,
                  textInputAction: TextInputAction.newline,
                  keyboardType: TextInputType.multiline,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(
                      context,
                    ).translate('typeMessage'),
                    hintStyle: TextStyle(
                      color: isDarkMode ? Colors.white54 : Colors.black54,
                    ),
                    filled: true,
                    fillColor: isDarkMode
                        ? Colors.white.withAlpha(25)
                        : Colors.grey.withAlpha(25),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: _isTyping
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white),
                  onPressed: _isTyping ? null : () => _handleSubmitted(_messageController.text),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
  }

  Future<void> _showReportDialog(ChatMessage message) async {
    if (message.isUserMessage || message.id == null) return;

    // Get a preview of the message (first 100 characters)
    final preview =
        message.text.length > 100
            ? '${message.text.substring(0, 100)}...'
            : message.text;

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => ContentReportDialog(
            contentId: message.id!,
            contentType: ContentType.aiMessage,
            contentPreview: preview,
          ),
    );

    if (result == true) {
      // Show confirmation that report was submitted
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Thank you for reporting this content. We will review it promptly.',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

class ChatMessage {
  final String text;
  final bool isUserMessage;
  final DateTime timestamp;
  final String? id; // Add unique ID for reporting

  ChatMessage({
    required this.text,
    required this.isUserMessage,
    required this.timestamp,
    String? id,
  }) : id = id ?? const Uuid().v4();
}

class ClaudeService {
  final String _apiKey;

  ClaudeService({required String apiKey}) : _apiKey = apiKey;

  Future<String> generateContent({
    required String prompt,
    required String systemInstructions,
  }) async {
    try {
      final url = Uri.parse('https://api.anthropic.com/v1/messages');
      
      final requestBody = {
        'model': 'claude-3-5-sonnet-20241022',
        'max_tokens': 1024,
        'system': systemInstructions,
        'messages': [
          {
            'role': 'user',
            'content': prompt,
          },
        ],
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final content = responseData['content'] as List;
        if (content.isNotEmpty) {
          final textBlock = content[0] as Map<String, dynamic>;
          return textBlock['text'] as String;
        }
        return 'No response generated.';
      } else if (response.statusCode == 401) {
        debugPrint('Claude API authentication error: ${response.statusCode} - ${response.body}');
        throw Exception('Authentication failed. Please check your API key.');
      } else {
        debugPrint('Claude API error: ${response.statusCode} - ${response.body}');
        throw Exception('API request failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Claude API error: $e');
      rethrow;
    }
  }

  Future<String> generateResponse(String prompt) async {
    return await generateContent(
      prompt: prompt,
      systemInstructions:
          "You are Mahoro, a supportive AI companion for mental health. Respond with empathy and care. Keep responses concise and helpful.",
    );
  }
}
