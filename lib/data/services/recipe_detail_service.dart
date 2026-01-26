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
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
  
  // Cache to store recipe details to avoid repeated API calls
  static final Map<String, Map<String, dynamic>> _recipeDetailCache = {};

  // Fetch recipe details from backend using legacy API
  static Future<Map<String, dynamic>> fetchRecipeDetails(String recipeName) async {
    // Return cached data if available
    if (_recipeDetailCache.containsKey(recipeName)) {
      final cachedData = _recipeDetailCache[recipeName]!;
      return cachedData;
    }

    try {
      // Use legacy generate-recipes-ingredient API for recipe details
      final response = await _dio.post(
        ApiEndpoints.generateRecipesIngredient,
        data: {
          "dish_name": recipeName,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          _recipeDetailCache[recipeName] = data;
          return data;
        }
      }
      
      // Return empty structure if API fails
      return {
        'Recipe Name': recipeName,
        'Description': 'A delicious recipe prepared with fresh ingredients.',
        'Ingredients Needed': {},
        'Preparation Steps': [],
        'Recipe Steps': [],
        'Cooking Time': '30 minutes',
        'Serving': '2',
        'Meal_Type': 'Lunch',
        'Nutrition': {'calories': 0, 'protein': 0, 'carbs': 0, 'fat': 0},
        'Cookware': [],
      };
    } catch (e) {
      debugPrint('Error fetching recipe details: $e');
      // Return empty structure on error
      return {
        'Recipe Name': recipeName,
        'Description': 'A delicious recipe prepared with fresh ingredients.',
        'Ingredients Needed': {},
        'Preparation Steps': [],
        'Recipe Steps': [],
        'Cooking Time': '30 minutes',
        'Serving': '2',
        'Meal_Type': 'Lunch',
        'Nutrition': {'calories': 0, 'protein': 0, 'carbs': 0, 'fat': 0},
        'Cookware': [],
      };
    }
  }

  /// Generate image for recipe or ingredient using the unified image API
  static Future<String?> generateImage(String name, {bool isRecipe = true}) async {
    try {
      debugPrint("🖼️ [RecipeDetailService] Generating image for: $name (${isRecipe ? 'recipe' : 'ingredient'})");
      
      final response = await _dio.post(
        "/generate-image",
        data: {
          if (isRecipe) "dish_name": name else "ingredient_name": name,
        },
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic> && data.containsKey('image_url')) {
          String imageUrl = data['image_url'].toString();
          
          // Ensure HTTPS for S3 URLs
          if (imageUrl.startsWith('http://') && imageUrl.contains('s3')) {
            imageUrl = imageUrl.replaceFirst('http://', 'https://');
            debugPrint("🔒 [RecipeDetailService] Converted S3 URL to HTTPS: $imageUrl");
          }
          
          debugPrint("✅ [RecipeDetailService] Image generated: $imageUrl");
          return imageUrl;
        }
      }
      
      debugPrint("❌ [RecipeDetailService] Image generation failed: ${response.statusCode}");
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
    _recipeDetailCache.clear();
  }

  /// Get service status
  static String getServiceMode() {
    return 'INSTANT MODE (No MongoDB/Cache)';
  }
}
