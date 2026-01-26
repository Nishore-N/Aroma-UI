import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class EmojiService {
  static final EmojiService _instance = EmojiService._internal();
  final Map<String, String> _emojiMap = {};
  final Map<String, String> _metricsMap = {};
  bool _isInitialized = false;

  factory EmojiService() {
    return _instance;
  }

  EmojiService._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Make sure the path matches exactly what's in pubspec.yaml
      final String jsonString = await rootBundle.loadString('assets/top_100_grocery_emoji_mapping.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      _emojiMap.clear();
      _metricsMap.clear();
      for (var item in jsonData['items']) {
        final name = item['name'].toLowerCase();
        _emojiMap[name] = item['emoji'];
        if (item['metrics'] != null) {
          _metricsMap[name] = item['metrics'];
        }
      }
      
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error loading emoji mapping: $e');
      // Clear maps on error
      _emojiMap.clear();
      _metricsMap.clear();
    }
  }

  /// Returns the emoji for the given ingredient name, or null if no emoji is found
  /// This allows the UI to handle the default case with a custom image
  /// Returns the metrics for the given ingredient name, or null if not found
  String? getMetricsForIngredient(String ingredientName) {
    if (!_isInitialized) return null;
    
    // Try exact match first
    final lowerName = ingredientName.toLowerCase().trim();
    if (_metricsMap.containsKey(lowerName)) {
      return _metricsMap[lowerName]!;
    }
    
    // Try partial matches
    final words = lowerName.split(RegExp(r'\s+')).where((word) => word.length > 2).toList();
    for (var word in words) {
      if (_metricsMap.containsKey(word)) {
        return _metricsMap[word]!;
      }
    }
    
    // Try to match by singular/plural forms
    if (lowerName.endsWith('s')) {
      final singular = lowerName.substring(0, lowerName.length - 1);
      if (_metricsMap.containsKey(singular)) {
        return _metricsMap[singular]!;
      }
    } else {
      final plural = '${lowerName}s';
      if (_metricsMap.containsKey(plural)) {
        return _metricsMap[plural]!;
      }
    }
    
    return null;
  }

  /// Returns the emoji for the given ingredient name, or null if no emoji is found
  String? getEmojiForIngredient(String ingredientName) {
    if (!_isInitialized) {
      return null; // Return null to use the default image
    }
    
    // Normalize the input name
    final lowerName = ingredientName.toLowerCase().trim();
    
    // Try exact match first
    if (_emojiMap.containsKey(lowerName)) {
      return _emojiMap[lowerName]!;
    }
    
    // Try partial matches with different strategies
    // 1. Check if any word in the ingredient name matches a key
    final words = lowerName.split(RegExp(r'\s+')).where((word) => word.length > 2).toList();
    for (var word in words) {
      if (_emojiMap.containsKey(word)) {
        return _emojiMap[word]!;
      }
    }
    
    // 2. Check if any key is contained in the ingredient name
    for (var entry in _emojiMap.entries) {
      if (lowerName.contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }
    
    // 3. Special case mappings for common variations
    final specialMappings = {
      'large eggs': '🥚',
      'chicken breast': '🍗',
      'cherry tomatoes': '🍅',
      'ground beef': '🥩',
      'olive oil': '🫒',
      'green onion': '🧅',
      'spring onion': '🧅',
      'bell pepper': '🫑',
      'sweet pepper': '🫑',
    };
    
    if (specialMappings.containsKey(lowerName)) {
      return specialMappings[lowerName]!;
    }
    
    // 4. Try to match by singular/plural forms
    if (lowerName.endsWith('s')) {
      final singular = lowerName.substring(0, lowerName.length - 1);
      if (_emojiMap.containsKey(singular)) {
        return _emojiMap[singular]!;
      }
    } else {
      final plural = '${lowerName}s';
      if (_emojiMap.containsKey(plural)) {
        return _emojiMap[plural]!;
      }
    }
    
    // Return null if no match found
    return null;
  }
}
