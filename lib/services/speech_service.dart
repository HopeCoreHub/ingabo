import 'package:flutter_tts/flutter_tts.dart';

class SpeechService {
  // Text-to-speech
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;
  
  // Speech-to-text (disabled)
  bool _isListening = false;
  
  // Initialize speech service
  Future<void> initialize() async {
    // Initialize text-to-speech
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    
    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
    });
    
    // Speech-to-text initialization disabled
  }
  
  // Set language for text-to-speech
  Future<void> setLanguage(String languageCode) async {
    String ttsLanguage = 'en-US';
    
    // Map language code to TTS language code
    switch (languageCode) {
      case 'English':
        ttsLanguage = 'en-US';
        break;
      case 'French':
        ttsLanguage = 'fr-FR';
        break;
      case 'Swahili':
        ttsLanguage = 'sw';
        break;
      case 'Kinyarwanda':
        ttsLanguage = 'rw';
        break;
      default:
        ttsLanguage = 'en-US';
    }
    
    await _flutterTts.setLanguage(ttsLanguage);
  }
  
  // Speak text
  Future<void> speak(String text) async {
    if (_isSpeaking) {
      await stop();
    }
    
    _isSpeaking = true;
    await _flutterTts.speak(text);
  }
  
  // Stop speaking
  Future<void> stop() async {
    _isSpeaking = false;
    await _flutterTts.stop();
  }
  
  // Check if speaking
  bool get isSpeaking => _isSpeaking;
  
  // Start listening for speech (disabled)
  Future<void> startListening({
    required Function(String) onResult,
    required Function() onListeningComplete,
    String? languageCode,
  }) async {
    // Speech recognition functionality disabled
    _isListening = false;
    onResult('Speech recognition is currently disabled');
    onListeningComplete();
  }
  
  // Stop listening (disabled)
  Future<void> stopListening() async {
    _isListening = false;
    // No implementation needed as speech recognition is disabled
  }
  
  // Check if listening
  bool get isListening => _isListening;
  
  // Dispose
  void dispose() {
    _flutterTts.stop();
    // No need to stop speech recognition as it's disabled
  }
} 