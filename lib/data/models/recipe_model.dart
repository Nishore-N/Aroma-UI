// lib/data/models/recipe_model.dart
class RecipeModel {
  final String id;
  final String title;
  final String cuisine;
  final String cookTime;
  final String image;
  final bool isSaved;
  final String? description;
  final int servings;
  final int calories;
  final List<String> ingredients;
  final List<String> instructions;
  final Map<String, dynamic>? fullRecipeData; // Store complete backend data

  RecipeModel({
    required this.id,
    required this.title,
    required this.cuisine,
    required this.cookTime,
    required this.image,
    this.isSaved = false,
    this.description,
    this.servings = 1,
    this.calories = 0,
    List<String>? ingredients,
    List<String>? instructions,
    this.fullRecipeData,
  }) : ingredients = ingredients ?? [],
       instructions = instructions ?? [];

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    return RecipeModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? json['recipe_name'] ?? 'Untitled Recipe',
      cuisine: json['cuisine'] ?? 'Unknown Cuisine',
      cookTime: json['cookTime']?.toString() ?? json['total_time']?.toString() ?? json['cooking_time']?.toString() ?? json['time']?.toString() ?? 'N/A',
      image: json['image'] ?? json['recipe_image_url'] ?? '', // Handle both field names
      isSaved: json['isSaved'] ?? false,
      description: json['description'],
      servings: (json['servings'] as num?)?.toInt() ?? 1,
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      ingredients: List<String>.from(json['ingredients'] ?? []),
      instructions: List<String>.from(json['instructions'] ?? []),
    );
  }

  RecipeModel copyWith({
    String? id,
    String? title,
    String? cuisine,
    String? cookTime,
    String? image,
    bool? isSaved,
    String? description,
    int? servings,
    int? calories,
    List<String>? ingredients,
    List<String>? instructions,
  }) {
    return RecipeModel(
      id: id ?? this.id,
      title: title ?? this.title,
      cuisine: cuisine ?? this.cuisine,
      cookTime: cookTime ?? this.cookTime,
      image: image ?? this.image,
      isSaved: isSaved ?? this.isSaved,
      description: description ?? this.description,
      servings: servings ?? this.servings,
      calories: calories ?? this.calories,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'cuisine': cuisine,
      'cookTime': cookTime,
      'image': image,
      'isSaved': isSaved,
      'description': description,
      'servings': servings,
      'calories': calories,
      'ingredients': ingredients,
      'instructions': instructions,
    };
  }
}