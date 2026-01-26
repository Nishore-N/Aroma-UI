import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_endpoints.dart';

class PantryImageService {
  static const String _cacheKey = 'pantry_image_cache';
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
  ));

  String _normalizeName(String name) => name.toLowerCase().trim();

  /// Generate an image for a pantry item by name
  Future<String?> generateItemImage(String name) async {
    try {
      final String url = ApiEndpoints.generateImageUrl;
      final normalized = _normalizeName(name);
      
      // Sanitize name to avoid potential metadata errors (Non-ASCII characters)
      final String safeName = normalized.replaceAll(RegExp(r'[^\x00-\x7F]'), ' ').trim();
      
      debugPrint('🎨 [PantryImage] Requesting image for: $safeName at $url');

      // Match the payload format expected by the API (based on RecipeDetailService)
      final response = await _dio.post(
        url,
        data: {
          "recipe_name": safeName,
          "dish_name": safeName,
          "ingredient_name": safeName,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        debugPrint('📥 [PantryImage] API Response for $safeName: $data');
        
        if (data is Map<String, dynamic>) {
          String? imageUrl;
          
          // Try multiple common keys for the image URL
          imageUrl = data['image_url']?.toString() ?? 
                     data['imageUrl']?.toString() ?? 
                     data['url']?.toString() ??
                     data['image']?.toString();
          
          // Check nested 'data' key
          if (imageUrl == null && data['data'] is Map) {
            final inner = data['data'] as Map;
            imageUrl = inner['image_url']?.toString() ?? 
                       inner['imageUrl']?.toString() ?? 
                       inner['url']?.toString() ??
                       inner['image']?.toString();
          }
          
          // Check nested 'results' key
          if (imageUrl == null && data['results'] is Map) {
            final results = data['results'] as Map;
            if (results.isNotEmpty) {
              final firstVal = results.values.first;
              if (firstVal is Map) {
                imageUrl = firstVal['image_url']?.toString() ?? 
                           firstVal['imageUrl']?.toString() ??
                           firstVal['url']?.toString();
              }
            }
          }
          
          if (imageUrl != null && imageUrl.isNotEmpty && imageUrl != "null") {
            // Ensure HTTPS for S3 URLs if necessary
            if (imageUrl.startsWith('http://') && imageUrl.contains('s3')) {
              imageUrl = imageUrl.replaceFirst('http://', 'https://');
            }
            
            debugPrint('✅ [PantryImage] Generated image for $safeName: $imageUrl');
            await saveImageToCache(normalized, imageUrl);
            return imageUrl;
          }
        }
      }
      debugPrint('⚠️ [PantryImage] Failed to generate image for $normalized: ${response.statusCode} ${response.data}');
      return null;
    } catch (e) {
      debugPrint('❌ [PantryImage] Error generating image for $name: $e');
      return null;
    }
  }

  /// Batch generate images for missing items
  Future<void> generateMissingImages(List<String> itemNames) async {
    final cache = await getCachedImages();
    final missingNames = itemNames.where((name) => !cache.containsKey(_normalizeName(name))).toList();

    if (missingNames.isEmpty) {
      debugPrint('ℹ️ [PantryImage] All items have cached images.');
      return;
    }

    debugPrint('🎨 [PantryImage] Generating ${missingNames.length} missing images...');
    
    // Process sequentially to be safe with rate limits, or use Future.wait for parallel
    for (final name in missingNames) {
      await generateItemImage(name);
    }
  }

  /// Get name-to-URL mapping from cache
  Future<Map<String, String>> getCachedImages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? rawCache = prefs.getString(_cacheKey);
      if (rawCache != null) {
        return Map<String, String>.from(jsonDecode(rawCache));
      }
    } catch (e) {
      debugPrint('❌ [PantryImage] Error reading cache: $e');
    }
    return {};
  }

  /// Save a single image URL to cache
  Future<void> saveImageToCache(String name, String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, String> cache = await getCachedImages();
      cache[_normalizeName(name)] = url;
      await prefs.setString(_cacheKey, jsonEncode(cache));
    } catch (e) {
      debugPrint('❌ [PantryImage] Error saving to cache: $e');
    }
  }

  /// Clear the entire image cache
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      debugPrint('🧹 [PantryImage] Image cache cleared');
    } catch (e) {
      debugPrint('❌ [PantryImage] Error clearing cache: $e');
    }
  }
}
