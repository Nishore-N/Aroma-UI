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

  /// Weekly recipes generation (Mocked)
  Future<List<dynamic>> generateWeeklyRecipes(Map<String, dynamic> preferences) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    debugPrint('📋 [Home Service] Returning MOCK weekly recipes');
    
    return [
      {
        "recipe_name": "Paneer Butter Masala",
        "cuisine": "Indian",
        "total_time": "35 min",
        "recipe_image_url": "https://images.pexels.com/photos/9609850/pexels-photo-9609850.jpeg",
        "description": "Rich and creamy paneer dish with butter and spices.",
        "servings": 4,
        "nutrition": {
          "calories": 450
        },
        "ingredients": [
          {"item": "Paneer", "quantity": "250g"},
          {"item": "Butter", "quantity": "50g"},
          {"item": "Tomato Puree", "quantity": "1 cup"},
          {"item": "Cream", "quantity": "2 tbsp"},
          {"item": "Spices", "quantity": "as needed"}
        ],
        "cooking_steps": [
          {"instruction": "Heat butter in a pan and add spices."},
          {"instruction": "Add tomato puree and cook until oil separates."},
          {"instruction": "Add paneer cubes and simmer for 5 minutes."},
          {"instruction": "Garnish with cream and serve hot."}
        ]
      },
      {
        "recipe_name": "Vegetable Biryani",
        "cuisine": "Indian",
        "total_time": "45 min",
        "recipe_image_url": "https://images.pexels.com/photos/12737656/pexels-photo-12737656.jpeg",
        "description": "Aromatic rice dish curried with mix vegetables and herbs.",
        "servings": 4,
        "nutrition": {
          "calories": 380
        },
        "ingredients": [
          {"item": "Basmati Rice", "quantity": "2 cups"},
          {"item": "Mixed Vegetables", "quantity": "2 cups"},
          {"item": "Onions", "quantity": "2"},
          {"item": "Biryani Masala", "quantity": "2 tbsp"},
          {"item": "Yogurt", "quantity": "1/2 cup"}
        ],
        "cooking_steps": [
          {"instruction": "Soak rice for 30 minutes."},
          {"instruction": "Sauté vegetables with spices and yogurt."},
          {"instruction": "Layer rice and vegetables in a pot."},
          {"instruction": "Cook on low heat (dum) for 20 minutes."}
        ]
      },
       {
        "recipe_name": "Aloo Gobi",
        "cuisine": "Indian",
        "total_time": "25 min",
        "recipe_image_url": "https://images.pexels.com/photos/2474661/pexels-photo-2474661.jpeg",
        "description": "Classic stir-fry with potatoes and cauliflower.",
        "servings": 3,
        "nutrition": {
          "calories": 220
        },
        "ingredients": [
          {"item": "Potatoes", "quantity": "2 large"},
          {"item": "Cauliflower", "quantity": "1 medium"},
          {"item": "Turmeric", "quantity": "1 tsp"},
          {"item": "Cumin Seeds", "quantity": "1 tsp"},
          {"item": "Coriander", "quantity": "garnish"}
        ],
        "cooking_steps": [
          {"instruction": "Heat oil and add cumin seeds."},
          {"instruction": "Add potatoes and cook for 5 minutes."},
          {"instruction": "Add cauliflower and spices, cover and cook."},
          {"instruction": "Garnish with fresh coriander."}
        ]
      }
    ];
  }
}