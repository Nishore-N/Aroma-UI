import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // Singleton pattern
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  AppConfig._internal();

  // Make fields nullable and remove late
  String? _geminiApiKey;
  String? _geminiModelName;
  String? _geminiEndpoint;

  // Getters with null checks
  String get geminiApiKey => _geminiApiKey ?? 
      (throw Exception('AppConfig not initialized. Call init() first.'));
  String get geminiModelName => _geminiModelName ?? 'gemini-pro';
  String get geminiEndpoint => _geminiEndpoint ?? 
      'https://generativelanguage.googleapis.com/v1beta/models/';

  // Initialize the configuration
  Future<void> init() async {
    try {
      try {
        await dotenv.load(fileName: ".env");
      } catch (e) {
        debugPrint('Failed to load .env file in AppConfig: $e');
        // Continue with default values
      }
      
      _geminiApiKey = dotenv.env['GEMINI_API_KEY'];
      _geminiModelName = dotenv.env['GEMINI_MODEL_NAME'] ?? 'gemini-pro';
      _geminiEndpoint = dotenv.env['GEMINI_ENDPOINT'] ?? 
          'https://generativelanguage.googleapis.com/v1beta/models/';
      
      // Validate required environment variables
      if (_geminiApiKey == null || _geminiApiKey!.isEmpty) {
        debugPrint('Warning: GEMINI_API_KEY is not set in .env file - using placeholder');
        _geminiApiKey = 'test_api_key_placeholder'; // Temporary fallback
        // throw Exception('GEMINI_API_KEY is not set in .env file');
      }
    } catch (e) {
      debugPrint('Error initializing AppConfig: $e');
      // Set default values even on error
      _geminiApiKey = 'test_api_key_placeholder';
      _geminiModelName = 'gemini-pro';
      _geminiEndpoint = 'https://generativelanguage.googleapis.com/v1beta/models/';
    }
  }

  // Helper method to get the full Gemini API URL
  String getGeminiApiUrl() {
    // If the endpoint already contains 'generateContent', return it as is
    if (geminiEndpoint.contains('generateContent')) {
      return geminiEndpoint;
    }
    // Otherwise, construct the full URL
    return '${geminiEndpoint}${geminiModelName}:generateContent';
  }

  // Helper method to get headers for API requests
  Map<String, String> getGeminiHeaders() {
    return {
      'Content-Type': 'application/json',
      'x-goog-api-key': geminiApiKey,
    };
  }
}

// Global instance of the configuration
final appConfig = AppConfig();
