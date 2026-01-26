import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/api_endpoints.dart';

class IngredientImageService {
  static bool _isInitialized = false;
  static const String _fallbackImagePath = 'assets/images/pantry/temp_pantry.png';
  static String get _baseUrl => ApiEndpoints.baseUrl;

  /// Normalize ingredient name for consistent lookup
  static String _normalizeIngredientName(String ingredientName) {
    return ingredientName.toLowerCase().trim();
  }

  static Future<void> initialize() async {
    if (!_isInitialized) {
      _isInitialized = true;
      if (kDebugMode) {
        print('✅ Ingredient Image Service initialized (Simple Mode)');
      }
    }
  }

  static Future<String?> getIngredientImage(String ingredientName, {String? imageUrl}) async {
    await initialize();
    
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return imageUrl;
    }

    final normalizedName = _normalizeIngredientName(ingredientName);
    
    // Return a direct backend URL based on normalized name
    // This removes all SQLite and SharedPreferences caching dependencies
    return '$_baseUrl/ingredient_images/${normalizedName.replaceAll(' ', '_')}.png';
  }

  static Future<void> clearCache() async {
    // No-op in simple mode
  }

  static Future<int> getCacheSize() async {
    return 0;
  }

  static Future<void> removeCachedImage(String ingredientName) async {
    // No-op in simple mode
  }

  static Future<void> preloadImages(List<String> ingredientNames) async {
    // No-op in simple mode
  }
}
