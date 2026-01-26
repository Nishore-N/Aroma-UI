import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_endpoints.dart';

class PreferenceApiService {
  static String get _baseUrl => ApiEndpoints.baseUrl;

  static Future<Map<String, dynamic>> generateRecipes(
    List<Map<String, dynamic>> ingredients,
    Map<String, dynamic> preferences,
  ) async {
    try {
      final url = Uri.parse(ApiEndpoints.generateRecipesIngredient);

      // ====================================================================
      // FUTURE USE: Advanced preference combinations system
      // ====================================================================
      // To enable multi-combination recipe generation, uncomment the following
      // block and comment out the simple request below:
      /*
      // Generate multiple preference combinations for diverse recipes
      final preferenceCombinations = _generatePreferenceCombinations(preferences);
      
      final List<Map<String, dynamic>> allRecipes = [];
      
      // Send requests for each preference combination
      for (final combination in preferenceCombinations) {
        final body = {
          'Meal_Type': [combination['meal_type'] ?? 'lunch'],
          'Dietary_Restrictions': combination['diet'] ?? 'None',
          'Cookware_Utensils': combination['cookware'] ?? 'None',
          'Cooking_Time': combination['time'] ?? '30 minutes',
          'Cuisine_Preference': combination['cuisine'] ?? 'Any',
          'Serving': int.tryParse(combination['servings']?.toString() ?? '1') ?? 1,
          'Ingredients_Available': ingredients,
        };

        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          final result = jsonDecode(response.body);
          final recipes = List<Map<String, dynamic>>.from(result['data']?['Recipes'] ?? []);
          allRecipes.addAll(recipes);
          print('✅ Got ${recipes.length} recipes for combination: ${combination['diet']}/${combination['cuisine']}');
        } else {
          print('❌ Failed to fetch recipes for combination: ${response.statusCode}');
        }
      }

      // Remove duplicate recipes based on dish name
      final uniqueRecipes = <Map<String, dynamic>>[];
      final Set<String> seenDishes = {};
      
      for (final recipe in allRecipes) {
        final dishName = recipe["Dish"]?.toString().toLowerCase().trim() ?? '';
        if (dishName.isNotEmpty && !seenDishes.contains(dishName)) {
          seenDishes.add(dishName);
          uniqueRecipes.add(recipe);
        }
      }

      print('🎯 Total unique recipes after combining: ${uniqueRecipes.length}');
      
      return {
        'data': {
          'Recipes': uniqueRecipes
        }
      };
      */
      // ====================================================================

      // CURRENT: Simple single preference request
      final body = {
        'Meal_Type': [preferences['meal_type'] ?? 'lunch'],
        'Dietary_Restrictions': preferences['diet'] ?? 'None',
        'Cookware_Utensils': preferences['cookware'] ?? 'None',
        'Cooking_Time': preferences['time'] ?? '30 minutes',
        'Cuisine_Preference': preferences['cuisine'] ?? 'Any',
        'Serving': int.tryParse(preferences['servings']?.toString() ?? '1') ?? 1,
        'Ingredients_Available': ingredients,
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 202) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch recipes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error generating recipes: $e');
    }
  }

  // ====================================================================
  // FUTURE USE: Preference combination generator
  // ====================================================================
  // This method generates multiple preference combinations for diverse recipes
  // Uncomment when needed for advanced recipe generation
  /*
  static List<Map<String, dynamic>> _generatePreferenceCombinations(Map<String, dynamic> preferences) {
    final combinations = <Map<String, dynamic>>[];
    
    // Get primary preferences
    final primaryDiet = preferences['diet'] ?? 'None';
    final primaryCuisine = preferences['cuisine'] ?? 'Any';
    final primaryMealType = preferences['meal_type'] ?? 'lunch';
    final primaryCookware = preferences['cookware'] ?? 'None';
    final primaryTime = preferences['time'] ?? '30 minutes';
    final servings = preferences['servings'] ?? '1';

    // 1. Primary combination (exact preferences)
    combinations.add({
      'diet': primaryDiet,
      'cuisine': primaryCuisine,
      'meal_type': primaryMealType,
      'cookware': primaryCookware,
      'time': primaryTime,
      'servings': servings,
    });

    // 2. Same diet, different cuisines
    if (primaryCuisine != 'Any') {
      final alternativeCuisines = ['North Indian', 'South Indian', 'Chinese', 'Italian', 'Continental'];
      for (final cuisine in alternativeCuisines) {
        if (cuisine != primaryCuisine) {
          combinations.add({
            'diet': primaryDiet,
            'cuisine': cuisine,
            'meal_type': primaryMealType,
            'cookware': primaryCookware,
            'time': primaryTime,
            'servings': servings,
          });
        }
      }
    }

    // 3. Same cuisine, different meal types
    final alternativeMealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];
    for (final mealType in alternativeMealTypes) {
      if (mealType != primaryMealType) {
        combinations.add({
          'diet': primaryDiet,
          'cuisine': primaryCuisine,
          'meal_type': mealType,
          'cookware': primaryCookware,
          'time': primaryTime,
          'servings': servings,
        });
      }
    }

    // 4. Different cooking times
    final alternativeTimes = ['5 - 10 minutes', '15 minutes', '30 minutes', '45 minutes'];
    for (final time in alternativeTimes) {
      if (time != primaryTime) {
        combinations.add({
          'diet': primaryDiet,
          'cuisine': primaryCuisine,
          'meal_type': primaryMealType,
          'cookware': primaryCookware,
          'time': time,
          'servings': servings,
        });
      }
    }

    // 5. Different cookware options
    final alternativeCookware = ['Pan', 'Pot', 'Oven', 'Pressure Cooker'];
    for (final cookware in alternativeCookware) {
      if (cookware != primaryCookware) {
        combinations.add({
          'diet': primaryDiet,
          'cuisine': primaryCuisine,
          'meal_type': primaryMealType,
          'cookware': cookware,
          'time': primaryTime,
          'servings': servings,
        });
      }
    }

    // Limit combinations to avoid too many API calls
    return combinations.take(8).toList();
  }
  */
  // ====================================================================
}