import 'package:flutter/material.dart';
import 'dart:math';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

const String _envClaudeApiKey =
    String.fromEnvironment('CLAUDE_API_KEY', defaultValue: '');

class MahoroPage extends BaseScreen {
  const MahoroPage({super.key});

  @override
  State<MahoroPage> createState() => _MahoroPageState();
}

class _MahoroPageState extends BaseScreenState<MahoroPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  late AnimationController _typingAnimController;
  List<ChatMessage> _messages = [];
  bool _isTyping = false;
  String _currentLanguage = 'EN';
  String _currentLanguageName = 'English';
  bool _isApiKeyValid = true;
  String _conversationId = '';

  // Firebase instance
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Claude service
  ClaudeService? _claudeService;

  final Map<String, String> _languageNames = {
    'EN': 'English',
    'RW': 'Kinyarwanda',
    'FR': 'Français',
    'SW': 'Swahili',
  };

  // Conversation history for API
  List<Map<String, dynamic>> _conversationHistory = [];
  
  // Conversation storage consent
  bool _conversationStorageConsent = false;
  
  // Maximum messages to keep in history (to prevent PII leakage and cost spikes)
  static const int _maxHistoryMessages = 20;
  
  // Maximum conversation age in days (30 days)
  static const int _maxConversationAgeDays = 30;

  // Get API key securely
  Future<String?> _getApiKey() async {
    return await AuthService.getApiKey();
  }

  @override
  void initState() {
    super.initState();
    _typingAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat();

    // Initialize greeting message with localized text
    _initializeGreeting();

    // Create a new conversation ID
    _createNewConversation();

    // Load previous conversation if any
    _loadPreviousConversation();

    // Initialize Claude service
    _initializeClaudeService();
  }

  void _initializeGreeting() {
    // Get localized greeting
    final greeting = AppLocalizations.of(context).translate('murahoImMahoro');
    _messages.add(
      ChatMessage(
        text: greeting,
        isUserMessage: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
      ),
    );
    _conversationHistory.add({
      "role": "assistant",
      "content": greeting,
    });
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

      // Check if conversation is too old (older than max age)
      if (conversationData.containsKey('lastUpdated')) {
        final lastUpdated = DateTime.parse(conversationData['lastUpdated'] as String);
        final ageInDays = DateTime.now().difference(lastUpdated).inDays;
        if (ageInDays > _maxConversationAgeDays) {
          // Delete old conversation
          await conversationDoc.reference.delete();
          return;
        }
      }

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

      // Get messages - limit to max history messages
      if (conversationData.containsKey('messages')) {
        final messages = conversationData['messages'] as List<dynamic>;
        // Only keep the most recent messages
        final recentMessages = messages.length > _maxHistoryMessages
            ? messages.sublist(messages.length - _maxHistoryMessages)
            : messages;

        setState(() {
          // Clear existing messages and history
          _messages.clear();
          _conversationHistory.clear();

          for (var message in recentMessages) {
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

      // Only save if user has consented
      if (!_conversationStorageConsent) {
        return;
      }

      final userId = authService.userId!;

      // Limit messages to prevent PII leakage and cost spikes
      final messagesToSave = _messages.length > _maxHistoryMessages
          ? _messages.sublist(_messages.length - _maxHistoryMessages)
          : _messages;

      // Create a list of message data to save (minimize stored data)
      final List<Map<String, dynamic>> messagesData = [];

      for (var message in messagesToSave) {
        // Only store essential data - truncate very long messages
        final content = message.text.length > 1000
            ? '${message.text.substring(0, 1000)}...'
            : message.text;
        
        messagesData.add({
          'role': message.isUserMessage ? 'user' : 'assistant',
          'content': content,
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
            'consentGiven': true,
          }, SetOptions(merge: true));

      // Clean up old conversations (older than max age)
      await _cleanupOldConversations(userId);

      debugPrint('Saved conversation to Firebase');
    } catch (e) {
      debugPrint('Error saving conversation to Firebase: $e');
      // Continue even if saving fails
    }
  }

  Future<void> _cleanupOldConversations(String userId) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: _maxConversationAgeDays));
      final oldConversations = await _db
          .collection('users')
          .doc(userId)
          .collection('mahoro_conversations')
          .where('lastUpdated', isLessThan: cutoffDate.toIso8601String())
          .get();

      for (var doc in oldConversations.docs) {
        await doc.reference.delete();
      }

      debugPrint('Cleaned up ${oldConversations.docs.length} old conversations');
    } catch (e) {
      debugPrint('Error cleaning up old conversations: $e');
    }
  }

  Future<void> _requestConversationStorageConsent() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (!authService.isLoggedIn || authService.userId == null) {
      return; // No need for consent if not logged in
    }

    // Check if consent was already given
    final prefs = await SharedPreferences.getInstance();
    final consentKey = 'mahoro_conversation_storage_consent_${authService.userId}';
    final hasConsented = prefs.getBool(consentKey) ?? false;

    if (hasConsented) {
      setState(() {
        _conversationStorageConsent = true;
      });
      return;
    }

    // Show consent dialog
    if (!mounted) return;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        title: LocalizedText('conversationStorageConsentTitle'),
        content: LocalizedText('conversationStorageConsentMessage'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: LocalizedText('decline'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: LocalizedText('accept'),
          ),
        ],
      ),
    );

    if (shouldSave == true) {
      await prefs.setBool(consentKey, true);
      setState(() {
        _conversationStorageConsent = true;
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _typingAnimController.dispose();
    super.dispose();
  }

  Future<void> _initializeClaudeService() async {
    final storedKey = await _getApiKey();
    final apiKey = _envClaudeApiKey.isNotEmpty
        ? _envClaudeApiKey
        : (storedKey != null && storedKey.isNotEmpty ? storedKey : null);

    if (apiKey != null && apiKey.isNotEmpty) {
      _claudeService = ClaudeService(apiKey: apiKey);
      setState(() {
        _isApiKeyValid = true;
      });
      debugPrint(
        _envClaudeApiKey.isNotEmpty
            ? "Initialized Claude AI service using environment key"
            : "Initialized Claude AI service using stored key",
      );
    } else {
      setState(() {
        _isApiKeyValid = false;
      });
      debugPrint("No Claude API key available");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showMissingApiKeyDialog();
        }
      });
    }
  }

  Future<void> _showMissingApiKeyDialog() async {
    if (_envClaudeApiKey.isNotEmpty) {
      return;
    }

    if (!mounted) return;

    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    final TextEditingController controller = TextEditingController();

    final enteredKey = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor:
              isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: LocalizedText(
            'claudeApiKeyRequired',
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LocalizedText(
                'mahoroNeedsValidApiKey',
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).translate('claudeApiKey'),
                  hintText: 'sk-ant-...',
                ),
                autofocus: true,
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: LocalizedText('cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(controller.text.trim());
              },
              child: LocalizedText('save'),
            ),
          ],
        );
      },
    );

    if (enteredKey != null && enteredKey.isNotEmpty) {
      await AuthService.storeApiKey(enteredKey);
      setState(() {
        _isApiKeyValid = true;
        _claudeService = ClaudeService(apiKey: enteredKey);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).translate('apiKeySaved'),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      setState(() {
        _isApiKeyValid = false;
      });
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

  Future<String> _getAnthropicResponse(String userMessage) async {
    try {
      // Get API key securely
      final apiKey = _envClaudeApiKey.isNotEmpty
          ? _envClaudeApiKey
          : (await _getApiKey() ?? '');
      if (apiKey.isEmpty) {
        setState(() {
          _isApiKeyValid = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showMissingApiKeyDialog();
          }
        });
        return "API key not found. Please contact support.";
      }

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

      try {
        debugPrint("Making API request to Claude...");
        debugPrint("API Key available: ${apiKey.isNotEmpty}");

        // Reinitialize Claude service with the current API key
        _claudeService = ClaudeService(apiKey: apiKey);

        // Generate response using Claude
        final response = await _claudeService!.generateContent(
          prompt: userMessage,
          systemInstructions: systemPrompt,
        );

        debugPrint("Received response from Claude (length: ${response.length})");
        return response;
      } catch (e) {
        debugPrint('Claude API Error: $e');
        debugPrint('Error type: ${e.runtimeType}');
        debugPrint('Error message: ${e.toString()}');
        
        if (e.toString().contains('authentication') || 
            e.toString().contains('401') ||
            e.toString().contains('API key')) {
          setState(() {
            _isApiKeyValid = false;
          });
          return AppLocalizations.of(context).translate('imHavingTroubleWithAuthentication');
        } else if (e.toString().contains('timeout') || 
                   e.toString().contains('Network') ||
                   e.toString().contains('internet')) {
          return AppLocalizations.of(context).translate('imHavingTroubleConnecting');
        } else if (e.toString().contains('rate limit') || 
                   e.toString().contains('429')) {
          return AppLocalizations.of(context).translate('tooManyRequestsPleaseWait');
        } else {
          final baseMessage = AppLocalizations.of(context).translate('imHavingTroubleConnecting');
          final emergencyGuidance = AppLocalizations.of(context).translate('ifInImmediateDangerCallEmergency');
          return '$baseMessage $emergencyGuidance';
        }
      }
    } catch (e) {
      debugPrint('Exception: $e');
      final baseMessage = AppLocalizations.of(context).translate('imSorryIEncounteredAnError');
      final emergencyGuidance = AppLocalizations.of(context).translate('ifInImmediateDangerCallEmergency');
      return '$baseMessage $emergencyGuidance';
    }
  }

  void _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;

    // Request consent for conversation storage on first message
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.isLoggedIn && !_conversationStorageConsent) {
      await _requestConversationStorageConsent();
    }

    _messageController.clear();
    _addMessage(text, true);

    // Show typing indicator
    setState(() {
      _isTyping = true;
    });

    try {
      // Get response from Claude
      final response = await _getAnthropicResponse(text);

      if (mounted) {
        setState(() {
          _isTyping = false;
        });

        _addMessage(response, false);
        
        // Save conversation after adding message
        _saveConversation();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTyping = false;
        });

        _addMessage(
          AppLocalizations.of(context).translate('imSorryIEncounteredAnError'),
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
                      LocalizedText(
                        _isApiKeyValid
                            ? 'aiSupportActive'
                            : 'apiConnectionError',
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
          if (!_isApiKeyValid)
            TextButton.icon(
              onPressed: _showMissingApiKeyDialog,
              icon: Icon(
                Icons.vpn_key,
                color:
                    highContrastMode
                        ? (isDarkMode ? Colors.white : Colors.black)
                        : accentColor,
                size: 18,
              ),
              label: LocalizedText(
                'enterApiKey',
                style: TextStyle(
                  color:
                      highContrastMode
                          ? (isDarkMode ? Colors.white : Colors.black)
                          : accentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
                                    LocalizedText(
                                      'report',
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
          SnackBar(
            content: Text(
              AppLocalizations.of(context).translate('thankYouForReportingContent'),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
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
      // Validate API key
      if (_apiKey.isEmpty) {
        debugPrint('Claude API Error: API key is empty');
        throw Exception('API key is missing. Please contact support.');
      }

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

      debugPrint('Claude API: Making request to ${url.toString()}');
      debugPrint('Claude API: API key prefix: ${_apiKey.substring(0, 10)}...');
      debugPrint('Claude API: Request body length: ${jsonEncode(requestBody).length}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('Claude API: Request timeout after 30 seconds');
          throw Exception('Request timeout. Please check your internet connection and try again.');
        },
      );

      debugPrint('Claude API: Response status: ${response.statusCode}');
      debugPrint('Claude API: Response body length: ${response.body.length}');

      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body) as Map<String, dynamic>;
          final content = responseData['content'] as List;
          if (content.isNotEmpty) {
            final textBlock = content[0] as Map<String, dynamic>;
            final text = textBlock['text'] as String;
            debugPrint('Claude API: Successfully received response (length: ${text.length})');
            return text;
          }
          debugPrint('Claude API: Empty content in response');
          return 'No response generated.';
        } catch (e) {
          debugPrint('Claude API: Error parsing response: $e');
          debugPrint('Claude API: Response body: ${response.body}');
          throw Exception('Failed to parse API response. Please try again.');
        }
      } else if (response.statusCode == 401) {
        debugPrint('Claude API authentication error: ${response.statusCode}');
        debugPrint('Claude API error body: ${response.body}');
        throw Exception('Authentication failed. Please check your API key.');
      } else if (response.statusCode == 429) {
        debugPrint('Claude API rate limit error: ${response.statusCode}');
        throw Exception('Rate limit exceeded. Please wait a moment and try again.');
      } else if (response.statusCode >= 500) {
        debugPrint('Claude API server error: ${response.statusCode}');
        debugPrint('Claude API error body: ${response.body}');
        throw Exception('Server error. Please try again later.');
      } else {
        debugPrint('Claude API error: ${response.statusCode}');
        debugPrint('Claude API error body: ${response.body}');
        throw Exception('API request failed: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      debugPrint('Claude API network error: $e');
      throw Exception('Network error. Please check your internet connection and try again.');
    } on FormatException catch (e) {
      debugPrint('Claude API format error: $e');
      throw Exception('Invalid response format. Please try again.');
    } catch (e) {
      debugPrint('Claude API unexpected error: $e');
      if (e.toString().contains('timeout')) {
        rethrow;
      }
      throw Exception('An unexpected error occurred: ${e.toString()}');
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
