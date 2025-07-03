import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:math';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'services/auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MahoroPage extends StatefulWidget {
  const MahoroPage({super.key});

  @override
  State<MahoroPage> createState() => _MahoroPageState();
}

class _MahoroPageState extends State<MahoroPage> with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  late AnimationController _typingAnimController;
  final List<ChatMessage> _messages = [
    ChatMessage(
      text: "Muraho! I'm Mahoro, your supportive AI companion. How can I help you today? You can speak to me in Kinyarwanda, English, Swahili, or French.",
      isUserMessage: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
    ),
  ];
  bool _isTyping = false;
  String _currentLanguage = 'FR';
  String _currentLanguageName = 'Français';
  bool _isApiKeyValid = true;
  
  final Map<String, String> _languageNames = {
    'EN': 'English',
    'RW': 'Kinyarwanda',
    'FR': 'Français',
    'SW': 'Swahili',
  };

  // Anthropic API configuration
  static const String _apiUrl = 'https://api.anthropic.com/v1/messages';
  final List<Map<String, dynamic>> _conversationHistory = [
    {
      "role": "assistant",
      "content": "Muraho! I'm Mahoro, your supportive AI companion. How can I help you today? You can speak to me in Kinyarwanda, English, Swahili, or French."
    }
  ];
  
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
    
    // Store API key securely on first run
    _storeApiKey();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _typingAnimController.dispose();
    super.dispose();
  }

  Future<void> _storeApiKey() async {
    // Check if we already have an API key stored
    final storedKey = await AuthService.getApiKey();
    if (storedKey == null || storedKey.isEmpty) {
      // Store the API key securely - combining the parts from user
      final apiKey = 'sk-ant-api03-cPvtJs6ea-Wh-3YC3_TwFayAMOW9MqWuSwAA4bPQ9Xd1ouQqD8hcrVgfzL8mSaecvgwADqkSOnianmkSBUbm0Q-cTKusAAA';
      await AuthService.storeApiKey(apiKey);
    }
  }

  void _setLanguage(String langCode) {
    setState(() {
      _currentLanguage = langCode;
      _currentLanguageName = _languageNames[langCode] ?? langCode;
    });
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
        "content": text
      });
    });
  }

  Future<String> _getAnthropicResponse(String userMessage) async {
    try {
      // Use simulation mode for development - API key issues
      final bool useSimulation = true; // Set to false to use actual API
      
      if (useSimulation) {
                 // Simulate AI response after a realistic delay
         print("Using simulation mode instead of API");
         await Future.delayed(Duration(milliseconds: 1500 + Random().nextInt(1000)));
        
        // Select response based on language
        final Map<String, List<String>> simulatedResponses = {
          'EN': [
            "I understand how you feel. Let's work through this together.",
            "Thank you for sharing that with me. Is there anything specific you'd like to talk about?",
            "I'm here to support you. Would it help to explore some coping strategies?",
            "You're not alone in feeling this way. Many people have similar experiences.",
            "That sounds challenging. I'm here to listen whenever you need someone to talk to.",
          ],
          'FR': [
            "Je comprends ce que vous ressentez. Travaillons ensemble sur ce problème.",
            "Merci de partager cela avec moi. Y a-t-il quelque chose de spécifique dont vous aimeriez parler?",
            "Je suis là pour vous soutenir. Serait-il utile d'explorer quelques stratégies d'adaptation?",
            "Vous n'êtes pas seul à ressentir cela. Beaucoup de personnes vivent des expériences similaires.",
            "Cela semble difficile. Je suis là pour vous écouter quand vous avez besoin de quelqu'un à qui parler.",
          ],
          'RW': [
            "Ndumva ibyo wumva. Reka dukorane hamwe kuri ibi.",
            "Urakoze kugira icyo unsangiza. Hari ikintu kihariye wifuza kuvuga?",
            "Ndi hano kugira ngo ngufashe. Byafasha se kureba ingamba zimwe zo kwihangana?",
            "Ntabwo uri wenyine mu byo wumva. Abantu benshi bafite uburambe busa.",
            "Ibyo biragora. Ndi hano kugira ngo nkumve igihe ukeneye umuntu wo kuvugana.",
          ],
          'SW': [
            "Ninaelewa unavyohisi. Hebu tufanye kazi pamoja.",
            "Asante kwa kushiriki hilo na mimi. Je, kuna jambo lolote mahususi ambalo ungependa kuzungumzia?",
            "Niko hapa kukusaidia. Je, itasaidia kuchunguza baadhi ya mikakati ya kukabiliana?",
            "Wewe si peke yako kuhisi hivi. Watu wengi wana uzoefu sawa.",
            "Hiyo inaonekana kuwa changamoto. Niko hapa kukusikiliza wakati wowote unapohitaji mtu wa kuzungumza naye.",
          ],
        };
        
        // Get responses for current language or default to English
        final responses = simulatedResponses[_currentLanguage] ?? simulatedResponses['EN']!;
        
        // Return a random response
        return responses[Random().nextInt(responses.length)];
      }

      // Get API key securely instead of hardcoding
      final apiKey = await _getApiKey() ?? '';
      if (apiKey.isEmpty) {
        setState(() {
          _isApiKeyValid = false;
        });
        return "API key not found. Please contact support.";
      }
      
      final headers = {
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
        'accept': 'application/json',
      };

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
      
      // Convert conversation history to the format expected by Claude API
      final List<Map<String, dynamic>> formattedMessages = [];
      for (var message in _conversationHistory) {
        formattedMessages.add({
          "role": message["role"],
          "content": message["content"]
        });
      }
      
      final body = jsonEncode({
        "model": "claude-3-haiku-20240307",
        "max_tokens": 1000,
        "system": systemPrompt,
        "messages": formattedMessages,
      });

      print("Making API request to Claude...");
      print("API URL: $_apiUrl");
      print("Request body: $body");
      
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 15), onTimeout: () {
        throw TimeoutException("Connection timed out. Please check your internet connection.");
      });

      print("API response status: ${response.statusCode}");
      print("API response body: ${response.body}");
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['content'][0]['text'];
      } else if (response.statusCode == 401) {
        print('Authentication error: ${response.statusCode} - ${response.body}');
        setState(() {
          _isApiKeyValid = false;
        });
        return "I'm having trouble with authentication. Please contact support.";
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
        return "I'm having trouble connecting right now. Please try again later.";
      }
    } on TimeoutException {
      return "The connection timed out. Please check your internet connection and try again.";
    } catch (e) {
      print('Exception: $e');
      return "I'm sorry, I encountered an error. Please try again.";
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
      // Get response from Claude API
      final response = await _getAnthropicResponse(text);
      
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
        
        _addMessage("I'm sorry, I encountered an error. Please try again.", false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF111827) : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildLanguageStatus(),
            Expanded(
              child: _buildChatList(),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final accentColor = isDarkMode ? const Color(0xFFA855F7) : const Color(0xFFE53935);
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accentColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mahoro',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Your 24/7\nsupport companion',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              height: 1.2,
            ),
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
    final isSelected = _currentLanguage == langCode;
    
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => _setLanguage(langCode),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
          ),
          child: Center(
            child: Text(
              langCode,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? accentColor : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageStatus() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final accentColor = isDarkMode ? const Color(0xFFA855F7) : const Color(0xFFE53935);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withOpacity(0.3),
                ),
                child: Icon(
                  Icons.smart_toy_outlined,
                  color: accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentLanguageName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isApiKeyValid ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isApiKeyValid ? 'AI Support Active' : 'API Connection Error',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: (isDarkMode ? Colors.black : Colors.grey.shade200).withOpacity(0.3),
            ),
            child: Icon(
              Icons.volume_up,
              color: accentColor,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final accentColor = isDarkMode ? const Color(0xFFA855F7) : const Color(0xFFE53935);
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      reverse: true,
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (_isTyping && index == 0) {
          return _buildTypingIndicator(accentColor);
        }
        
        final adjustedIndex = _isTyping ? index - 1 : index;
        final message = _messages[_messages.length - 1 - adjustedIndex];
        return _buildChatBubble(message, accentColor);
      },
    );
  }

  Widget _buildTypingIndicator(Color accentColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor,
            ),
            child: const Icon(
              Icons.smart_toy_outlined,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              color: accentColor.withOpacity(0.7),
            ),
            child: AnimatedBuilder(
              animation: _typingAnimController,
              builder: (context, child) {
                return Row(
                  children: List.generate(3, (i) {
                    final delay = i * 0.3;
                    final sinValue = sin((_typingAnimController.value * 2 * pi) + delay);
                    final size = 6.0 + (sinValue + 1) * 2.0;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
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

  Widget _buildChatBubble(ChatMessage message, Color accentColor) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    final alignment = message.isUserMessage ? 
        CrossAxisAlignment.end : CrossAxisAlignment.start;
    
    final bubbleColor = message.isUserMessage 
        ? (isDarkMode ? const Color(0xFF1E293B) : Colors.grey.shade200)
        : (isDarkMode ? accentColor : accentColor);
    
    final textColor = message.isUserMessage 
        ? (isDarkMode ? Colors.white : Colors.black87) 
        : Colors.white;
    
    final radius = message.isUserMessage 
        ? const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: message.isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUserMessage) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor,
              ),
              child: const Icon(
                Icons.smart_toy_outlined,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            child: Column(
              crossAxisAlignment: alignment,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    color: bubbleColor,
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 16,
                      color: textColor,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ),
          ),
          
          if (message.isUserMessage) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDarkMode ? const Color(0xFF1E293B) : Colors.grey.shade200,
              ),
              child: Icon(
                Icons.person,
                color: isDarkMode ? Colors.white : Colors.black87,
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        _buildInputArea(),
        _buildSupportInfo(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildInputArea() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final accentColor = isDarkMode ? const Color(0xFFA855F7) : const Color(0xFFE53935);
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: AnimatedContainer(
        duration: ThemeProvider.animationDurationMedium,
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Type your message',
                  hintStyle: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onSubmitted: _isTyping ? null : _handleSubmitted,
                enabled: !_isTyping,
              ),
            ),
            IconButton(
              icon: Icon(Icons.mic, color: isDarkMode ? Colors.white54 : Colors.black54),
              onPressed: _isTyping ? null : () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Voice input coming soon')),
                );
              },
            ),
            const SizedBox(width: 4),
            AnimatedContainer(
              duration: ThemeProvider.animationDurationShort,
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isTyping ? accentColor.withOpacity(0.6) : accentColor,
              ),
              child: IconButton(
                icon: _isTyping 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: _isTyping ? null : () => _handleSubmitted(_messageController.text),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportInfo() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: (isDarkMode ? Colors.black : Colors.grey.shade200).withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.favorite,
            color: Color(0xFFA855F7),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'AI-powered support in multiple languages - Crisis support: 3029 (Isange) | 3512 (Police)',
              style: TextStyle(
                color: isDarkMode ? Colors.white.withOpacity(0.7) : Colors.black87.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
  }
}

class ChatMessage {
  final String text;
  final bool isUserMessage;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUserMessage,
    required this.timestamp,
  });
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  
  @override
  String toString() => message;
} 