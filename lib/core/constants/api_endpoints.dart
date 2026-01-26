import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class ApiEndpoints {
  // Centralized Base URL
  // Centralized Base URL
  static String get baseUrl => dotenv.env['API_BASE_URL']!;

  // Endpoint Methods/Getters
  static String get pantryList => dotenv.env['PANTRY_LIST_URL']!;
  static String get pantryAdd => dotenv.env['PANTRY_ADD_URL']!;
  static String get pantryRemove => dotenv.env['PANTRY_REMOVE_URL']!;
  static String get detectQty => dotenv.env['DETECT_QTY_URL']!;
  static String get generateRecipesIngredient => dotenv.env['GENERATE_RECIPES_INGREDIENT_URL']!;
  static String get recipesWeekly => dotenv.env['RECIPES_WEEKLY_URL']!;
  static String get registerUser => dotenv.env['REGISTER_USER_URL']!;
  static String get loginUser => dotenv.env['LOGIN_USER_URL']!;
  static String get loginUserOtp => dotenv.env['LOGIN_USER_OTP_URL']!;
  static String get homescreenBanner => dotenv.env['homescreen_banner_url']!;
  // static String get paginationUrl => dotenv.env['pagination_url']!; // Keeping this as a possible fallback if needed, but logic will switch

  static String get recipeBaseUrl => dotenv.env['RECIPE_BASE_URL']!;

  // Cuisine Specific URLs (Constructed from Recipe Base URL + Endpoint)
  static String get urlAny => '$recipeBaseUrl/${dotenv.env['ENDPOINT_ANY']}';
  static String get urlIndian => '$recipeBaseUrl/${dotenv.env['ENDPOINT_INDIAN']}';
  static String get urlMexican => '$recipeBaseUrl/${dotenv.env['ENDPOINT_MEXICAN']}';
  static String get urlItalian => '$recipeBaseUrl/${dotenv.env['ENDPOINT_ITALIAN']}';
  static String get urlChinese => '$recipeBaseUrl/${dotenv.env['ENDPOINT_CHINESE']}';
  static String get urlAmerican => '$recipeBaseUrl/${dotenv.env['ENDPOINT_AMERICAN']}';
  static String get urlThai => '$recipeBaseUrl/${dotenv.env['ENDPOINT_THAI']}';
  static String get urlMediterranean => '$recipeBaseUrl/${dotenv.env['ENDPOINT_MEDITERRANEAN']}';
  static String get urlJapanese => '$recipeBaseUrl/${dotenv.env['ENDPOINT_JAPANESE']}';
  static String get urlFrench => '$recipeBaseUrl/${dotenv.env['ENDPOINT_FRENCH']}';
  static String get urlKorean => '$recipeBaseUrl/${dotenv.env['ENDPOINT_KOREAN']}';

  // Specific path for ingredient images
  static String ingredientImageUrl(String name) => '$baseUrl/ingredient_images/${name.replaceAll(' ', '_')}.png';

  // Helper for logging in debug mode
  static void debugPrintBaseUrl() {
    if (kDebugMode) {
      debugPrint('API base URL (from .env): $baseUrl');
    }
  }
}
