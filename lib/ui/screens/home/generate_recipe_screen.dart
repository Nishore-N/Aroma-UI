import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/services/home_recipe_service.dart';
import '../../../data/models/meal_plan_model.dart';
import '../../../state/pantry_state.dart';
import '../../widgets/recipe_card.dart';
import '../recipe_detail/recipe_detail_screen.dart';
import '../../widgets/cooking_loader.dart';
import '../../../core/services/auth_service.dart';
import '../auth/login_screen.dart';

class GenerateRecipeScreen extends StatefulWidget {
  const GenerateRecipeScreen({
    super.key, 
    this.usePantryIngredients = false, 
    this.pantryIngredients = const [], 
    this.preGeneratedRecipes = const []
  });

  final bool usePantryIngredients;
  final List<String> pantryIngredients;
  final List<Map<String, dynamic>> preGeneratedRecipes;

  @override
  State<GenerateRecipeScreen> createState() => _GenerateRecipeScreenState();
}

class _GenerateRecipeScreenState extends State<GenerateRecipeScreen> {
  final HomeRecipeService _homeRecipeService = HomeRecipeService();

  bool _isLoading = false;
  WeeklyMealPlan? _mealPlan;
  int _selectedDayIndex = 0;
  final Map<String, String> _recipeImages = {};

  @override
  void initState() {
    super.initState();
    if (widget.preGeneratedRecipes.isNotEmpty) {
      _mealPlan = WeeklyMealPlan.fromJson({'Days': widget.preGeneratedRecipes});
      _triggerImageGeneration();
    } else {
      _generateWeeklyRecipes();
    }
  }

  Future<void> _triggerImageGeneration() async {
    if (_mealPlan == null) return;
    
    // Generate images sequentially to avoid overwhelming the API
    for (var day in _mealPlan!.days) {
      for (var meal in day.meals) {
        await _fetchImageForMeal(meal);
      }
    }
  }

  Future<void> _fetchImageForMeal(Meal meal) async {
    final imageUrl = await _homeRecipeService.generateRecipeImage(meal.recipeName);
    if (imageUrl != null && mounted) {
      setState(() {
        meal.imageUrl = imageUrl;
        _recipeImages[meal.recipeName] = imageUrl;
      });
    }
  }

  Future<void> _retryImageGeneration(Meal meal) async {
    // Reset the image to show loading state
    setState(() {
      meal.imageUrl = null;
    });
    
    // Attempt to regenerate the image
    await _fetchImageForMeal(meal);
  }

  Future<void> _generateWeeklyRecipes() async {
    setState(() => _isLoading = true);

    try {
      List<String> ingredients = widget.pantryIngredients;
      if (ingredients.isEmpty) {
        final pantryState = Provider.of<PantryState>(context, listen: false);
        await pantryState.loadPantry();
        ingredients = pantryState.pantryItems.map((item) => item.name).toList();
      }

      final requestData = {
        "Cuisine_Preference": "Indian",
        "Dietary_Restrictions": "Vegetarian",
        "Cookware_Available": ["Microwave Oven"],
        "Meal_Type": ["Breakfast", "Lunch", "Dinner"],
        "Cooking_Time": "> 15 min",
        "Serving": "1",
        "Ingredients_Available": ingredients,
      };

      final dynamicResult = await _homeRecipeService.generateWeeklyRecipes(requestData);
      
      setState(() {
        _mealPlan = WeeklyMealPlan.fromJson({'Days': dynamicResult});
        _isLoading = false;
      });
      
      _triggerImageGeneration();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _navigateToRecipeDetail(Meal meal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailScreen(
          image: meal.imageUrl ?? '',
          title: meal.recipeName,
          cuisine: "Indian", // Default or extract if available
          cookTime: meal.cookingTime,
          servings: 1,
          ingredients: [], // Details not in this API
          fullRecipeData: meal.toJson(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: CookingLoader(message: "Cooking your weekly plan..."),
      );
    }

    if (_mealPlan == null || _mealPlan!.days.isEmpty) {
      return _buildEmptyState();
    }

    final currentDay = _mealPlan!.days[_selectedDayIndex];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Weekly Menu",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildDaySelector(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: currentDay.meals.length,
              itemBuilder: (context, index) {
                final meal = currentDay.meals[index];
                return _buildMealItem(meal);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _mealPlan!.days.length,
        itemBuilder: (context, index) {
          final isSelected = index == _selectedDayIndex;
          return GestureDetector(
            onTap: () => setState(() => _selectedDayIndex = index),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFF7A4A) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  "Day ${index + 1}",
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMealItem(Meal meal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          meal.mealType,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _navigateToRecipeDetail(meal),
          child: Container(
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Stack(
                    children: [
                      Container(
                        height: 180,
                        width: double.infinity,
                        color: Colors.grey.shade100,
                        child: meal.imageUrl != null
                            ? Image.network(meal.imageUrl!, fit: BoxFit.cover)
                            : const Center(child: CircularProgressIndicator(color: Color(0xFFFF7A4A))),
                      ),
                      // Retry button overlay
                      Positioned(
                        top: 12,
                        right: 12,
                        child: GestureDetector(
                          onTap: () => _retryImageGeneration(meal),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.refresh,
                              size: 20,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              meal.recipeName,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.favorite_border, color: Colors.grey, size: 20),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        meal.shortDescription,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            meal.cookingTime,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text("No recipes found", style: TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _generateWeeklyRecipes,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF7A4A)),
              child: const Text("Try Again"),
            ),
          ],
        ),
      ),
    );
  }
}
