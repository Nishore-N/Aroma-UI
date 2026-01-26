// lib/data/models/recipe_cache_model.dart
class RecipeDetailCache {
  final String recipeName;
  final String description;
  final Map<String, dynamic> nutrition;
  final List<String> cookware;
  final List<Map<String, dynamic>> preparationSteps;
  final DateTime cachedAt;

  RecipeDetailCache({
    required this.recipeName,
    required this.description,
    required this.nutrition,
    required this.cookware,
    required this.preparationSteps,
    required this.cachedAt,
  });

  factory RecipeDetailCache.fromJson(Map<String, dynamic> json) {
    return RecipeDetailCache(
      recipeName: json['recipe_name'] ?? '',
      description: json['description'] ?? '',
      nutrition: Map<String, dynamic>.from(json['nutrition'] ?? {}),
      cookware: List<String>.from(json['cookware'] ?? []),
      preparationSteps: List<Map<String, dynamic>>.from(json['preparation_steps'] ?? []),
      cachedAt: DateTime.parse(json['cached_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recipe_name': recipeName,
      'description': description,
      'nutrition': nutrition,
      'cookware': cookware,
      'preparation_steps': preparationSteps,
      'cached_at': cachedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toGeminiFormat() {
    return {
      'description': description,
      'nutrition': nutrition,
      'cookware': cookware,
      'steps': preparationSteps,
    };
  }
}

class CookingStepCache {
  final String recipeName;
  final int stepNumber;
  final String instruction;
  final List<String> tips;
  final List<Map<String, dynamic>> ingredients;
  final DateTime cachedAt;

  CookingStepCache({
    required this.recipeName,
    required this.stepNumber,
    required this.instruction,
    required this.tips,
    required this.ingredients,
    required this.cachedAt,
  });

  factory CookingStepCache.fromJson(Map<String, dynamic> json) {
    return CookingStepCache(
      recipeName: json['recipe_name'] ?? '',
      stepNumber: json['step_number'] ?? 0,
      instruction: json['instruction'] ?? '',
      tips: List<String>.from(json['tips'] ?? []),
      ingredients: List<Map<String, dynamic>>.from(json['ingredients'] ?? []),
      cachedAt: DateTime.parse(json['cached_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recipe_name': recipeName,
      'step_number': stepNumber,
      'instruction': instruction,
      'tips': tips,
      'ingredients': ingredients,
      'cached_at': cachedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toStepFormat() {
    return {
      'instruction': instruction,
      'tips': tips,
      'ingredients': ingredients,
    };
  }
}

class GeneratedRecipeCache {
  final String preferenceHash;
  final List<Map<String, dynamic>> recipes;
  final Map<String, String> recipeImages;
  final String cuisine;
  final DateTime cachedAt;

  GeneratedRecipeCache({
    required this.preferenceHash,
    required this.recipes,
    required this.recipeImages,
    required this.cuisine,
    required this.cachedAt,
  });

  factory GeneratedRecipeCache.fromJson(Map<String, dynamic> json) {
    return GeneratedRecipeCache(
      preferenceHash: json['preference_hash'] ?? '',
      recipes: List<Map<String, dynamic>>.from(json['recipes'] ?? []),
      recipeImages: Map<String, String>.from(json['recipe_images'] ?? {}),
      cuisine: json['cuisine'] ?? '',
      cachedAt: DateTime.parse(json['cached_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'preference_hash': preferenceHash,
      'recipes': recipes,
      'recipe_images': recipeImages,
      'cuisine': cuisine,
      'cached_at': cachedAt.toIso8601String(),
    };
  }
}
