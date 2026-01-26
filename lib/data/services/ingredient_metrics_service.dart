import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class IngredientMetricsService {
  static final IngredientMetricsService _instance = IngredientMetricsService._internal();
  factory IngredientMetricsService() => _instance;
  IngredientMetricsService._internal();

  Map<String, String> _metricsMap = {};
  bool _isLoaded = false;

  Future<void> loadMetrics() async {
    if (_isLoaded) return;

    try {
      final String jsonString = await rootBundle.loadString('assets/top_100_grocery_emoji_mapping.json');
      final Map<String, dynamic> data = json.decode(jsonString);
      
      final List<dynamic> items = data['items'] ?? [];
      
      for (var item in items) {
        final String name = item['name']?.toString().toLowerCase() ?? '';
        final String metrics = item['metrics']?.toString() ?? '';
        
        if (name.isNotEmpty && metrics.isNotEmpty) {
          _metricsMap[name] = metrics;
        }
      }
      
      _isLoaded = true;
      debugPrint('Loaded ${_metricsMap.length} ingredient metrics');
    } catch (e) {
      debugPrint('Error loading ingredient metrics: $e');
      _isLoaded = true; // Mark as loaded even on error to prevent retry loops
    }
  }

  String getMetricsForIngredient(String ingredientName) {
    if (!_isLoaded) {
      debugPrint("Metrics not loaded yet for: $ingredientName");
      return '';
    }
    
    final normalizedName = ingredientName.toLowerCase().trim();
    debugPrint("Looking for metrics for: '$normalizedName'");
    
    // Create a mapping for common ingredient variations
    final Map<String, String> commonVariations = {
      'eggs': 'chicken eggs',
      'large eggs': 'chicken eggs',
      'egg': 'chicken eggs',
      'tomatoes': 'tomato',
      'cherry tomatoes': 'tomato',
      'tomato': 'tomatoes',
      'aubergine': 'brinjal',
      'eggplant': 'brinjal',
      'brinjal': 'aubergine',
      'yogurt': 'curd',
      'natural yogurt': 'curd',
      'cheese': 'cheese',
      'cottage cheese': 'paneer',
      'bananas': 'banana',
      'banana': 'bananas',
      'chicken breast': 'chicken breast',
      'breast': 'chicken breast',
      'milk': 'milk',
    };
    
    // Try to normalize the ingredient name
    String searchName = normalizedName;
    if (commonVariations.containsKey(normalizedName)) {
      searchName = commonVariations[normalizedName]!;
      debugPrint("Normalized '$normalizedName' to '$searchName'");
    }
    
    // Try exact match first with normalized name
    if (_metricsMap.containsKey(searchName)) {
      final result = _metricsMap[searchName]!;
      debugPrint("Found exact match: $result");
      return result;
    }
    
    // Try exact match with original name
    if (_metricsMap.containsKey(normalizedName)) {
      final result = _metricsMap[normalizedName]!;
      debugPrint("Found exact match with original name: $result");
      return result;
    }
    
    // Try partial matches (common variations)
    for (String key in _metricsMap.keys) {
      if (key.contains(searchName) || searchName.contains(key)) {
        final result = _metricsMap[key]!;
        debugPrint("Found partial match: '$key' -> $result");
        return result;
      }
      
      if (key.contains(normalizedName) || normalizedName.contains(key)) {
        final result = _metricsMap[key]!;
        debugPrint("Found partial match with original: '$key' -> $result");
        return result;
      }
    }
    
    // Try word-based matching
    final List<String> searchWords = searchName.split(' ');
    for (String word in searchWords) {
      if (word.length > 2) { // Only check words longer than 2 characters
        for (String key in _metricsMap.keys) {
          if (key.contains(word) || word.contains(key)) {
            final result = _metricsMap[key]!;
            debugPrint("Found word-based match: '$word' in '$key' -> $result");
            return result;
          }
        }
      }
    }
    
    debugPrint("No metrics found for: $ingredientName");
    return '';
  }

  Map<String, String> getAllMetrics() {
    return Map.from(_metricsMap);
  }
}