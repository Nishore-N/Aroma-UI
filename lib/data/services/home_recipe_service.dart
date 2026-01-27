import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../core/constants/api_endpoints.dart';

class HomeRecipeService {
  
  Future<List<dynamic>> fetchBannerRecipes() async {
    final url = ApiEndpoints.homescreenBanner;
    debugPrint('🌐 [Home Service] Fetching banner recipes from: $url');
    
    try {
      final response = await http.get(Uri.parse(url));
      
      debugPrint('📥 [Home Service] Banner response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> recipes = data['recipes'] ?? [];
        debugPrint('✅ [Home Service] Fetched ${recipes.length} banner recipes');
        return recipes;
      } else {
        debugPrint('❌ [Home Service] Failed to fetch banner recipes: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ [Home Service] Exception fetching banner recipes: $e');
      return [];
    }
  }

  Future<List<dynamic>> fetchExploreRecipes({
    required String cuisine,
    int page = 2,
    int limit = 10,
  }) async {
    // Select the correct URL based on cuisine
    String url;
    switch (cuisine) {
      case "Indian":
        url = ApiEndpoints.urlIndian;
        break;
      case "Mexican":
        url = ApiEndpoints.urlMexican;
        break;
      case "Italian":
        url = ApiEndpoints.urlItalian;
        break;
      case "Chinese":
        url = ApiEndpoints.urlChinese;
        break;
      case "American":
        url = ApiEndpoints.urlAmerican;
        break;
      case "Thai":
        url = ApiEndpoints.urlThai;
        break;
      case "Mediterranean":
        url = ApiEndpoints.urlMediterranean;
        break;
      case "Japanese":
        url = ApiEndpoints.urlJapanese;
        break;
      case "French":
        url = ApiEndpoints.urlFrench;
        break;
      case "Korean":
        url = ApiEndpoints.urlKorean;
        break;
      case "Any":
      default:
        url = ApiEndpoints.urlAny;
        break;
    }

    print('🔴 DEBUG: Service fetchExploreRecipes called for $cuisine');
    print('🔴 DEBUG: URL: $url');
    debugPrint('🌐 [Home Service] Fetching explorer recipes for $cuisine from: $url');

    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      print('🔴 DEBUG: Response Status: ${response.statusCode}');
      print('🔴 DEBUG: Response Body Length: ${response.body.length}');
      
      debugPrint('📥 [Home Service] Explore response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> recipes = data['recipes'] ?? [];
        print('🔴 DEBUG: Fetched ${recipes.length} recipes for $cuisine');
        debugPrint('✅ [Home Service] Fetched ${recipes.length} explore recipes for $cuisine');
        return recipes;
      } else {
        debugPrint('❌ [Home Service] Failed to fetch explore recipes: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ [Home Service] Exception fetching explore recipes: $e');
      return [];
    }
  }

  /// Weekly recipes generation (Real API call)
  Future<List<dynamic>> generateWeeklyRecipes(Map<String, dynamic> preferences) async {
    final url = ApiEndpoints.recipesWeekly;
    debugPrint('🌐 [Home Service] Generating weekly recipes from: $url');
    debugPrint('📦 [Home Service] Request Body: ${json.encode(preferences)}');
    
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(preferences),
      ).timeout(const Duration(seconds: 120)); // Extended timeout for weekly generation
      
      debugPrint('📥 [Home Service] Weekly response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        // The API returns { "Days": [...] }
        return data['Days'] ?? [];
      } else {
        debugPrint('❌ [Home Service] Failed to generate weekly recipes: ${response.statusCode}');
        debugPrint('📄 [Home Service] Error response: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ [Home Service] Exception generating weekly recipes: $e');
      rethrow;
    }
  }

  /// Generate recipe image (Real API call)
  Future<String?> generateRecipeImage(String recipeName) async {
    final url = ApiEndpoints.recipesImage;
    debugPrint('🌐 [Home Service] Generating image for: $recipeName');
    
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"recipe_name": recipeName}),
      ).timeout(const Duration(seconds: 60)); // Increased timeout for image generation
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['ok'] == true && data['data'] != null) {
          return data['data']['imageUrl']?.toString();
        }
      }
      debugPrint('❌ [Home Service] Failed to generate image: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ [Home Service] Exception generating recipe image: $e');
      return null;
    }
  }
}