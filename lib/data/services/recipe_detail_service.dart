import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';

class RecipeDetailService {
  static String get _baseUrl => ApiEndpoints.baseUrl;
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 90),
      receiveTimeout: const Duration(seconds: 90),
    ),
  );
  
  // Fetch recipe details from backend using recipeId
  static Future<Map<String, dynamic>?> fetchRecipeDetails(String recipeId) async {
    try {
      // Use generate-recipes-ingredient API for recipe details with recipeId
      debugPrint('🚀 [RecipeDetailService] Fetching details for recipeId: $recipeId');
      debugPrint('🔗 [RecipeDetailService] URL: ${ApiEndpoints.generateRecipesIngredient}');
      
      final response = await _dio.post(
        ApiEndpoints.generateRecipesIngredient,
        data: {
          "recipeId": recipeId,
        },
      );

      debugPrint('📥 [RecipeDetailService] Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final rawData = response.data;
        if (rawData is Map<String, dynamic> && rawData['ok'] == true) {
          final dynamic dataField = rawData['data'];
          
          if (dataField is Map<String, dynamic>) {
            debugPrint('🍱 [RecipeDetailService] Data is Map, Keys: ${dataField.keys.join(', ')}');
            return dataField;
          } else if (dataField is List) {
             debugPrint('🍱 [RecipeDetailService] Data is List of length ${dataField.length}');
            // Try to find the specific recipe by ID
            final found = dataField.firstWhere(
              (item) => (item['_id']?.toString() == recipeId || item['id']?.toString() == recipeId),
              orElse: () => null,
            );
            
            if (found != null) {
              debugPrint('✅ [RecipeDetailService] Found matching recipe in list');
              return Map<String, dynamic>.from(found);
            } else if (dataField.isNotEmpty) {
              debugPrint('⚠️ [RecipeDetailService] Recipe ID not found in list, returning first item as fallback');
              return Map<String, dynamic>.from(dataField.first);
            }
          }
        } else {
          debugPrint('⚠️ [RecipeDetailService] Response "ok" is not true or data is malformed: $rawData');
        }
      }
      
      // Return null if API fails explicitly
      return null;
    } catch (e) {
      debugPrint('Error fetching recipe details: $e');
      // Return null on exception to avoid overwriting with bad data
      return null;
    }
  }

  /// Generate image for recipe or ingredient using the unified image API
  static Future<String?> generateImage(String name, {bool isRecipe = true}) async {
    try {
      // Sanitize name to avoid S3 metadata errors (Non-ASCII characters)
      final String safeName = name.replaceAll(RegExp(r'[^\x00-\x7F]'), ' ').trim();
      
      debugPrint("📤 [RecipeDetailService] Image API Payload: ${ {
        "recipe_name": safeName,
        "dish_name": safeName,
        if (!isRecipe) "ingredient_name": safeName,
      } }");

      final response = await _dio.post(
        ApiEndpoints.generateImageUrl,
        data: {
          "recipe_name": safeName,
          "dish_name": safeName,
          if (!isRecipe) "ingredient_name": safeName,
        },
      );
      
      final data = response.data;
      debugPrint("📄 [RecipeDetailService] Image API Response Body: $data");

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data is Map<String, dynamic>) {
          String? imageUrl;
          
          // Check for direct keys or nested 'data' or 'results'
          imageUrl = data['image_url']?.toString() ?? 
                     data['imageUrl']?.toString() ?? 
                     data['url']?.toString() ??
                     data['image']?.toString();
          
          if (imageUrl == null && data['data'] is Map) {
            final inner = data['data'] as Map;
            imageUrl = inner['image_url']?.toString() ?? 
                       inner['imageUrl']?.toString() ?? 
                       inner['url']?.toString() ??
                       inner['image']?.toString();
          }
          
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
            // Ensure HTTPS for S3 URLs
            if (imageUrl.startsWith('http://') && imageUrl.contains('s3')) {
              imageUrl = imageUrl.replaceFirst('http://', 'https://');
              debugPrint("🔒 [RecipeDetailService] Converted S3 URL to HTTPS: $imageUrl");
            }
            
            debugPrint("✅ [RecipeDetailService] Image generated: $imageUrl");
            return imageUrl;
          }
        }
      }
      
      debugPrint("❌ [RecipeDetailService] Image generation failed: ${response.statusCode}. Body: $data");
      return null;
    } catch (e) {
      debugPrint("❌ [RecipeDetailService] Image generation exception: $e");
      return null;
    }
  }

  /// Track recipe view - DISABLED in INSTANT mode
  static Future<void> trackRecipeView(String recipeName, Map<String, dynamic> recipeDetails) async {
    if (kDebugMode) {
      print('⚡ [RecipeDetailService] View tracking DISABLED in INSTANT mode for: $recipeName');
    }
    // No tracking - instant display only
  }

  /// Store recipe details - DISABLED in INSTANT mode
  static Future<void> storeRecipeDetails(String recipeName, Map<String, dynamic> recipeData) async {
    if (kDebugMode) {
      print('⚡ [RecipeDetailService] Storage DISABLED in INSTANT mode for: $recipeName');
    }
    // No storage - instant display only
  }

  /// Clear cache - DISABLED in INSTANT mode
  static Future<void> clearCache() async {
    if (kDebugMode) {
      print('⚡ [RecipeDetailService] Cache clearing DISABLED in INSTANT mode');
    }
  }

  /// Get service status
  static String getServiceMode() {
    return 'INSTANT MODE (No MongoDB/Cache)';
  }
}
