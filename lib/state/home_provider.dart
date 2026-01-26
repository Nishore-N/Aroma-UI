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

    // Parse cooking time - try multiple possible field names and formats
    String rawTime = "0";
    final possibleTimeFields = [
      "Cooking Time", "cooking_time", "total_time", "totalTime", 
      "cook_time", "prep_time", "preparation_time", "time"
    ];
    
    for (final field in possibleTimeFields) {
      if (item[field] != null && item[field].toString().isNotEmpty) {
        rawTime = item[field].toString();
        debugPrint(' Found time in field "$field": $rawTime');
        break;
      }
    }
    
    // Extract numeric value from various formats like "15 min", "15-20 min", "15-30", etc.
    String cookTimeStr = rawTime;
    
    // Try to extract the first number found
    final numberMatch = RegExp(r'\d+').firstMatch(rawTime);
    if (numberMatch != null) {
      cookTimeStr = numberMatch.group(0) ?? "0";
    } else {
      // If no numbers found, try to parse directly
      cookTimeStr = rawTime.replaceAll(RegExp(r'[^0-9]'), '');
    }
    
    final cookTime = int.tryParse(cookTimeStr) ?? 0;
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
        if (ing is Map && ing.containsKey('item')) {
          return ing['item']?.toString() ?? ing.toString();
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
    } else {
      debugPrint(' No title field found, using "Unknown Dish"');
    }

    // Use provided ID or generate from title
    final String id = item["id"]?.toString() ?? recipeTitle.replaceAll(' ', '_');

    return RecipeModel(
      id: id,
      title: recipeTitle,
      cuisine: item["cuisine"]?.toString() ?? "Indian",
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

  // Load banner recipes
  Future<void> loadBannerRecipes() async {
    try {
      isBannerLoading = true;
      notifyListeners(); // Notify loading state if needed
      
      final rawData = await _homeRecipeService.fetchBannerRecipes();
      if (rawData.isNotEmpty) {
        bannerRecipes = _normalizeRecipes(rawData);
      }
    } catch (e) {
      debugPrint('Error loading banner recipes: $e');
    } finally {
      isBannerLoading = false;
      notifyListeners();
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