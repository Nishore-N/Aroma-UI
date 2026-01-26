import 'package:flutter/foundation.dart';
import '../models/recipe_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/constants/api_endpoints.dart';

class RecipeService {
  final String baseUrl;
  
  RecipeService({String? baseUrl}) : baseUrl = baseUrl ?? ApiEndpoints.baseUrl;

  Future<RecipeModel> getRecipe(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/recipes/$id'));
      
      if (response.statusCode == 200) {
        return RecipeModel.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load recipe');
      }
    } catch (e) {
      debugPrint('Error fetching recipe: $e');
      rethrow;
    }
  }

  Future<List<RecipeModel>> getRecipes({int page = 1, int limit = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/recipes?page=$page&limit=$limit'),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => RecipeModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load recipes');
      }
    } catch (e) {
      debugPrint('Error fetching recipes: $e');
      rethrow;
    }
  }
}
