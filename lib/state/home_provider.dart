import 'package:flutter/material.dart';
import '../data/models/recipe_model.dart';
import '../data/services/home_recipe_service.dart';


class HomeProvider extends ChangeNotifier {

  bool isLoading = false;
  String? error;

  /// 🔥 UI EXPECTS RecipeModel
  List<RecipeModel> recipes = [];
  List<RecipeModel> bannerRecipes = [];
  bool isBannerLoading = false;
  
  final HomeRecipeService _homeRecipeService = HomeRecipeService();

  // Fallback recipes in case of API failure
  final List<RecipeModel> _fallbackRecipes = [
    RecipeModel(
      id: "f1",
      title: "Masala Dosa",
      cuisine: "Indian",
      cookTime: '15',
      image: "https://images.pexels.com/photos/5560763/pexels-photo-5560763.jpeg",
    ),
    RecipeModel(
      id: "f2",
      title: "Vegetable Upma",
      cuisine: "Indian",
      cookTime: '20',
      image: "https://images.pexels.com/photos/5848490/pexels-photo-5848490.jpeg",
    ),
  ];


  // NORMALIZE API RESPONSE → RecipeModel
  List<RecipeModel> _normalizeRecipes(List<dynamic> apiData) {
  return apiData.map<RecipeModel>((item) {
    debugPrint(' Recipe item keys: ${item.keys.toList()}');
    debugPrint(' Recipe item: $item');
    
    final Map<String, dynamic> imageObj =
        Map<String, dynamic>.from(item["Image"] ?? {});

    // Parse cooking time - try summing prep and cook time first
    int totalMinutes = 0;
    bool timeInfoFound = false;

    // Direct check for the common separate fields
    final cookTimeVal = item["cook_time"] ?? item["cooking_time"] ?? item["Cooking Time"];
    final prepTimeVal = item["prep_time"] ?? item["preparation_time"] ?? item["Preparation Time"];

    if (cookTimeVal != null || prepTimeVal != null) {
        final ct = int.tryParse(cookTimeVal.toString()) ?? 0;
        final pt = int.tryParse(prepTimeVal.toString()) ?? 0;
        totalMinutes = ct + pt;
        if (totalMinutes > 0) timeInfoFound = true;
    }

    String rawTime = totalMinutes.toString();
    
    if (!timeInfoFound) {
        final possibleTimeFields = [
          "total_time", "totalTime", "time", "Cooking Time", "cooking_time", "cook_time"
        ];
        
        for (final field in possibleTimeFields) {
          if (item[field] != null && item[field].toString().isNotEmpty && item[field].toString() != "0") {
            rawTime = item[field].toString();
            timeInfoFound = true;
            break;
          }
        }
    }
    
    // Extract numeric value from various formats like "15 min", "15-20 min", "15-30", etc.
    String cookTimeStr = rawTime;
    final numberMatch = RegExp(r'\d+').firstMatch(rawTime);
    if (numberMatch != null) {
      cookTimeStr = numberMatch.group(0) ?? "0";
    } else {
      cookTimeStr = rawTime.replaceAll(RegExp(r'[^0-9]'), '');
    }
    
    final cookTime = int.tryParse(cookTimeStr) ?? totalMinutes;
    debugPrint(' Parsed cookTime: $cookTime from raw: "$rawTime"');

    // Extract ingredients list from backend data
    List<String> ingredientStrings = [];
    if (item["Ingredients Needed"] != null && item["Ingredients Needed"] is Map) {
      ingredientStrings = (item["Ingredients Needed"] as Map)
          .entries
          .map((entry) => "${entry.key}: ${entry.value}")
          .toList();
    } else if (item["ingredients"] != null) {
      // Handle both list of maps and list of strings
      final List<dynamic> rawIngredients = item["ingredients"] as List<dynamic>;
      ingredientStrings = rawIngredients.map((ing) {
        if (ing is Map) {
          // Try to extract a clean name
          final name = ing['item'] ?? ing['name'] ?? ing['ingredient'] ?? ing.toString();
          final qty = ing['qty'] ?? ing['quantity'] ?? ing['amount'] ?? '';
          final unit = ing['unit']?.toString() ?? '';
          
          if (qty.toString().isNotEmpty || unit.isNotEmpty) {
            return "$name ($qty $unit)".trim().replaceAll(RegExp(r'\s+'), ' ');
          }
          return name.toString();
        } else {
          return ing.toString();
        }
      }).toList();
    }

    // Extract instructions from backend data
    List<String> instructionStrings = [];
    if (item["Recipe Steps"] != null && item["Recipe Steps"] is List) {
      instructionStrings = (item["Recipe Steps"] as List)
          .map((step) => step.toString())
          .where((s) => s.isNotEmpty)
          .toList();
    } else if (item["cooking_steps"] != null) {
      instructionStrings = (item["cooking_steps"] as List)
          .map((step) => step['instruction']?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    }

    // Try multiple possible field names for recipe title
    String recipeTitle = "Unknown Dish";
    if (item["recipe_name"] != null) {
      recipeTitle = item["recipe_name"].toString();
      debugPrint(' Found title in "recipe_name" field: $recipeTitle');
    } else if (item["Recipe Name"] != null) {
      recipeTitle = item["Recipe Name"].toString();
      debugPrint(' Found title in "Recipe Name" field: $recipeTitle');
    } else if (item["name"] != null) {
      recipeTitle = item["name"].toString();
      debugPrint(' Found title in "name" field: $recipeTitle');
    } else if (item["title"] != null) {
      recipeTitle = item["title"].toString();
      debugPrint(' Found title in "title" field: $recipeTitle');
    } else if (item["dish_name"] != null) {
      recipeTitle = item["dish_name"].toString();
      debugPrint(' Found title in "dish_name" field: $recipeTitle');
    } else if (imageObj["dish_name"] != null) {
      recipeTitle = imageObj["dish_name"].toString();
      debugPrint(' Found title in "Image.dish_name" field: $recipeTitle');
    } else if (imageObj["name"] != null) {
      recipeTitle = imageObj["name"].toString();
      debugPrint(' Found title in "Image.name" field: $recipeTitle');
    }

    // Use provided ID or generate from title
    final String id = item["_id"]?.toString() ?? item["id"]?.toString() ?? recipeTitle.replaceAll(' ', '_');

    // Improve cuisine detection
    String cuisine = "Indian";
    final possibleCuisineFields = ["cuisine", "Cuisine", "cuisine_type", "category", "Cuisine Type"];
    for (final field in possibleCuisineFields) {
      final val = item[field]?.toString();
      if (val != null && val.isNotEmpty && val.toLowerCase() != "unknown") {
        cuisine = val;
        break;
      }
    }

    return RecipeModel(
      id: id,
      title: recipeTitle,
      cuisine: cuisine,
      cookTime: cookTime.toString(),
      image: item["image_url"]?.toString() ?? 
           item["recipe_image_url"]?.toString() ??
           imageObj["image_url"]?.toString() ??
           "https://images.pexels.com/photos/1640777/pexels-photo-1640777.jpeg",
      isSaved: false,
      description: item["description"]?.toString() ?? "",
      servings: (item["servings"] as num?)?.toInt() ?? 1,
      calories: (item["nutrition"]?["calories"] as num?)?.toInt() ?? 0,
      ingredients: ingredientStrings,
      instructions: instructionStrings,
      fullRecipeData: Map<String, dynamic>.from(item), // Store complete backend data
    );
  }).toList();
}

  HomeProvider() {
    loadRecipes();
    loadBannerRecipes();
  }

  // Load recipes for Home screen - now uses fallback only
  Future<void> loadRecipes() async {
    // Rely on fallback recipes as the home generation API has been removed
    if (recipes.isEmpty) {
      recipes = List.from(_fallbackRecipes);
      notifyListeners();
    }
  }

  bool _stopImageGeneration = false;

  void stopImageGeneration() {
    _stopImageGeneration = true;
    notifyListeners();
  }

  // Load banner recipes
  Future<void> loadBannerRecipes() async {
    try {
      _stopImageGeneration = false; // Reset stop flag
      isBannerLoading = true;
      notifyListeners(); 
      
      final rawData = await _homeRecipeService.fetchBannerRecipes();
      if (rawData.isNotEmpty) {
        bannerRecipes = _normalizeRecipes(rawData);
        notifyListeners();
        
        // Start generating images sequentially
        _generateBannerImagesSequentially();
      }
    } catch (e) {
      debugPrint('Error loading banner recipes: $e');
    } finally {
      isBannerLoading = false;
      notifyListeners();
    }
  }

  // 🔹 Sequential image generation to avoid overwhelming the API
  Future<void> _generateBannerImagesSequentially() async {
    debugPrint('🎨 [HomeProvider] Starting sequential image generation for ${bannerRecipes.length} banner recipes...');
    
    for (int i = 0; i < bannerRecipes.length; i++) {
        if (_stopImageGeneration) {
          debugPrint('🛑 [HomeProvider] Image generation stopped by user action');
          break;
        }

        final recipe = bannerRecipes[i];
        
        // Only generate if image is the default fallback or empty
        final bool isFallback = recipe.image.contains('pexels.com') || recipe.image.isEmpty;
        
        if (isFallback) {
            try {
                debugPrint('🖼️ [HomeProvider] Generating image $i/${bannerRecipes.length} for: ${recipe.title}');
                
                final imageUrl = await _homeRecipeService.generateRecipeImage(recipe.title);
                
                if (imageUrl != null && imageUrl.isNotEmpty) {
                    bannerRecipes[i] = recipe.copyWith(image: imageUrl);
                    notifyListeners();
                    debugPrint('✅ [HomeProvider] Successfully generated image for: ${recipe.title}');
                } else {
                    debugPrint('⚠️ [HomeProvider] Failed to generate image for: ${recipe.title}');
                }
            } catch (e) {
                debugPrint('❌ [HomeProvider] Error generating image for ${recipe.title}: $e');
                // Continue to next recipe despite error
            }
            
            // Wait a small delay between requests to be safe
            await Future.delayed(const Duration(milliseconds: 500));
        }
    }
    
    if (!_stopImageGeneration) {
      debugPrint('🎉 [HomeProvider] Sequential image generation completed');
    }
  }

  List<RecipeModel> exploreRecipes = [];
  bool isExploreLoading = false;

  // Load explore recipes based on cuisine
  Future<void> loadExploreRecipes({required String cuisine, int page = 2, int limit = 10}) async {
    try {
      isExploreLoading = true;
      notifyListeners();
      final rawData = await _homeRecipeService.fetchExploreRecipes(cuisine: cuisine, page: page, limit: limit);
      if (rawData.isNotEmpty) {
        exploreRecipes = _normalizeRecipes(rawData);
      }
    } catch (e) {
      debugPrint('Error loading explore recipes: $e');
    } finally {
      isExploreLoading = false;
      notifyListeners();
    }
  }

  void toggleSaved(String recipeId) {
    final index = recipes.indexWhere((r) => r.id == recipeId);
    if (index == -1) return;

    recipes[index] = recipes[index].copyWith(
      isSaved: !recipes[index].isSaved,
    );

    notifyListeners();
  }
}