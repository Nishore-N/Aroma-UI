import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/services/home_recipe_service.dart';

import '../../../state/pantry_state.dart';

import '../../widgets/recipe_card.dart';
import '../recipe_detail/recipe_detail_screen.dart';
import '../../widgets/cooking_loader.dart';
import '../../../core/services/auth_service.dart';
import '../auth/login_screen.dart';

class GenerateRecipeScreen extends StatefulWidget {
  const GenerateRecipeScreen({super.key, this.usePantryIngredients = false, this.pantryIngredients = const [], this.preGeneratedRecipes = const []});

  final bool usePantryIngredients;
  final List<String> pantryIngredients;
  final List<Map<String, dynamic>> preGeneratedRecipes;

  @override
  State<GenerateRecipeScreen> createState() {
    print("🔍 DEBUG: GenerateRecipeScreen createState called");
    return _GenerateRecipeScreenState();
  }
}

class _GenerateRecipeScreenState extends State<GenerateRecipeScreen> {
  final HomeRecipeService _homeRecipeService = HomeRecipeService();

  bool _isLoading = false;
  List<Map<String, dynamic>> _weeklyRecipes = [];
  String _selectedDate = '';
  int _selectedDateIndex = 0;
  Timer? _imageCheckTimer;

  @override
  void initState() {
    super.initState();
    print("🔍 DEBUG: GenerateRecipeScreen initState called");
    _initializeDates();
    
    // Check if recipes are pre-generated
    if (widget.preGeneratedRecipes.isNotEmpty) {
      print("🔍 DEBUG: Using ${widget.preGeneratedRecipes.length} pre-generated recipes");
      setState(() {
        _weeklyRecipes = widget.preGeneratedRecipes;
        _isLoading = false;
      });
      // Start timer to check for image updates
      _startImageCheckTimer();
    } else {
      // Only generate if no pre-generated recipes are provided
      _generateWeeklyRecipes();
    }
  }

  @override
  void dispose() {
    _imageCheckTimer?.cancel();
    super.dispose();
  }

  void _initializeDates() {
    final now = DateTime.now();
    _selectedDate = '${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${_getDayAbbreviation(now.weekday)}';
  }

  String _getDayAbbreviation(int weekday) {
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return days[weekday - 1];
  }

  List<String> _generateWeekDates() {
    final now = DateTime.now();
    final dates = <String>[];
    
    for (int i = 0; i < 7; i++) {
      final date = now.add(Duration(days: i));
      final dateStr = '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${_getDayAbbreviation(date.weekday)}';
      dates.add(dateStr);
    }
    
    return dates;
  }

  Future<void> _generateWeeklyRecipes() async {
    setState(() {
      _isLoading = true;
    });

    // Show animation for a moment before starting generation
    await Future.delayed(const Duration(seconds: 1));



    try {
      List<String> pantryIngredients;

      if (widget.usePantryIngredients && widget.pantryIngredients.isNotEmpty) {
        // Use passed pantry ingredients
        pantryIngredients = widget.pantryIngredients;
        print("🔍 DEBUG: Using passed pantry ingredients: $pantryIngredients");
      } else {
        // Use PantryState provider instead of manual parsing
        final pantryState = Provider.of<PantryState>(context, listen: false);
        await pantryState.loadPantry(); // Ensure pantry is loaded
        
        pantryIngredients = pantryState.pantryItems.map((item) => item.name).toList();
        print("🔍 DEBUG: Loaded ${pantryIngredients.length} pantry ingredients from PantryState: $pantryIngredients");
      }

      print("🔍 DEBUG: Final pantry ingredients to use: $pantryIngredients");

      // Create multiple combinations with pantry ingredients
      final combinations = _createCombinations(pantryIngredients);
      print("🔍 DEBUG: Created ${combinations.length} combinations");
      
      // Use first combination for API call
      final selectedCombination = combinations.isNotEmpty ? combinations[0] : {
        "Cuisine_Preference": "Indian",
        "Dietary_Restrictions": "Vegetarian",
        "Cookware_Available": ["Microwave Oven"],
        "Meal_Type": ["Breakfast"],
        "Cooking_Time": "< 15 min",
        "Serving": "1",
        "Ingredients_Available": ["Lemon", "Avacado", "Carrot", "Brinjal", "Banana", "CARROTS"],
      };

      print("🔍 DEBUG: Using combination for recipe generation: $selectedCombination");
      print("🔍 DEBUG: Ingredients being sent to API: ${selectedCombination['Ingredients_Available']}");

      // Generate recipes using NEW service with instant text display
      debugPrint("🚀 [GenerateRecipeScreen] Starting recipe generation with instant display");
      
      final dynamicResult = await _homeRecipeService.generateWeeklyRecipes(selectedCombination);
      final recipes = List<Map<String, dynamic>>.from(dynamicResult);
      
      debugPrint("✅ [GenerateRecipeScreen] Recipes generated: ${recipes.length} recipes");
      
      setState(() {
        _weeklyRecipes = recipes;
        _isLoading = false;
      });
      
      debugPrint("🎯 [GenerateRecipeScreen] UI updated instantly, images loading in background");
      
      // Start timer to check for image updates every 2 seconds
      _startImageCheckTimer();
      
      print("✅ Generated ${recipes.length} weekly recipes");
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      print("❌ Error generating weekly recipes: $e");
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating recipes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startImageCheckTimer() {
    _imageCheckTimer?.cancel();
    _imageCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _checkForImageUpdates();
    });
  }

  void _checkForImageUpdates() {
    if (!mounted) return;
    
    bool hasUpdates = false;
    for (int i = 0; i < _weeklyRecipes.length; i++) {
      final recipe = _weeklyRecipes[i];
      // Check if image has been generated since last check
      if (recipe['image_generated'] == true && 
          recipe['image_url'] != null && 
          recipe['image_url'].toString().isNotEmpty) {
        hasUpdates = true;
        break;
      }
    }
    
    if (hasUpdates) {
      setState(() {
        // Refresh UI to show new images
      });
      debugPrint("🖼️ [GenerateRecipeScreen] Image updates detected, refreshing UI");
      
      // Stop timer after images are loaded
      _imageCheckTimer?.cancel();
    }
  }

  List<Map<String, dynamic>> _createCombinations(List<String> pantryIngredients) {
    print("🔍 DEBUG: _createCombinations called with ${pantryIngredients.length} ingredients");
    
    if (pantryIngredients.isEmpty) {
      print("🔍 DEBUG: No pantry ingredients available, returning empty combinations");
      return [];
    }

    final cuisines = ["Indian", "Italian", "Chinese", "Mexican"];
    final dietaryOptions = ["Vegetarian", "Vegan", "None"];
    final mealTypes = ["Breakfast", "Lunch", "Snacks", "Dinner"];
    final cookwareOptions = [["Microwave Oven"], ["Gas Stove", "Pan"], ["Oven"]];
    final cookingTimes = ["< 15 min", "< 30 min", "< 45 min"];
    final servings = ["1", "2", "4"];

    final combinations = <Map<String, dynamic>>[];
    
    // Create combinations for all meal types for a week
    // We'll create 7 combinations (one for each day) with all meal types
    for (int day = 0; day < 7; day++) {
      final combination = {
        "Cuisine_Preference": cuisines[day % cuisines.length],
        "Dietary_Restrictions": dietaryOptions[day % dietaryOptions.length],
        "Cookware_Available": cookwareOptions[day % cookwareOptions.length],
        "Meal_Type": mealTypes, // Include all meal types instead of just one
        "Cooking_Time": cookingTimes[day % cookingTimes.length],
        "Serving": servings[day % servings.length],
        "Ingredients_Available": pantryIngredients,
      };
      
      print("🔍 DEBUG: Created combination for day $day:");
      print("   - Cuisine: ${combination['Cuisine_Preference']}");
      print("   - Dietary: ${combination['Dietary_Restrictions']}");
      print("   - Cookware: ${combination['Cookware_Available']}");
      print("   - Meal Type: ${combination['Meal_Type']}");
      print("   - Cooking Time: ${combination['Cooking_Time']}");
      print("   - Serving: ${combination['Serving']}");
      print("   - Ingredients Count: ${(combination['Ingredients_Available'] as List).length}");
      
      combinations.add(combination);
    }

    print("🔍 DEBUG: Returning ${combinations.length} total combinations");
    return combinations;
  }

  List<Map<String, dynamic>> _getRecipesForDate(String date) {
    // Filter recipes for the selected date
    final recipesForDate = _weeklyRecipes
        .where((recipe) => recipe is Map<String, dynamic>)
        .cast<Map<String, dynamic>>()
        .where((recipe) {
          final recipeDate = recipe['Date']?.toString() ?? '';
          final dateParts = date.split(' ');
          if (dateParts.length >= 2) {
            final monthDay = dateParts[0];
            final recipeDateParts = recipeDate.split('-');
            if (recipeDateParts.length >= 3) {
              final recipeMonthDay = '${recipeDateParts[1]}-${recipeDateParts[2]}';
              return recipeMonthDay == monthDay;
            }
          }
          return false;
        }).toList();

    // Debug: Print all meal types for this date
    final mealTypes = recipesForDate.map((r) => r['Meal_Type']?.toString()).toSet();
    print("🔍 DEBUG: Meal types for date $date: $mealTypes");
    print("🔍 DEBUG: Total recipes for date $date: ${recipesForDate.length}");
    
    return recipesForDate;
  }

  void _navigateToRecipeDetail(dynamic recipe) {
    // Create a copy of the recipe data and enrich it with cuisine information
    final enrichedRecipeData = Map<String, dynamic>.from(recipe as Map<String, dynamic>);
    
    // Extract cuisine from multiple possible sources
    final cuisine = recipe['Cuisine']?.toString() ?? 
                   recipe['cuisine']?.toString() ?? 
                   recipe['Cuisine_Preference']?.toString() ?? 
                   recipe['Meal_Type']?.toString() ?? 
                   'Indian'; // Fallback
    
    // Ensure cuisine is available in the data for the detail screen
    if (!enrichedRecipeData.containsKey('Cuisine') && !enrichedRecipeData.containsKey('cuisine')) {
      enrichedRecipeData['Cuisine'] = cuisine;
      enrichedRecipeData['cuisine'] = cuisine;
      enrichedRecipeData['Cuisine_Preference'] = cuisine;
    }
    
    print("🍽️ DEBUG: Navigating to detail screen with cuisine: $cuisine");
    print("🍽️ DEBUG: Enriched recipe data keys: ${enrichedRecipeData.keys}");
    
    // Prepare ingredients list
    List<Map<String, dynamic>> ingredientsList = [];
    if (enrichedRecipeData['Ingredients Needed'] is Map) {
      (enrichedRecipeData['Ingredients Needed'] as Map).forEach((key, value) {
        ingredientsList.add({'item': key, 'quantity': value, 'image': ''});
      });
    } else if (enrichedRecipeData['ingredients'] is List) {
       ingredientsList = List<Map<String, dynamic>>.from(enrichedRecipeData['ingredients']);
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailScreen(
          image: enrichedRecipeData['image_url']?.toString() ?? '',
          title: enrichedRecipeData['Recipe Name']?.toString() ?? 'Unknown',
          cuisine: cuisine,
          cookTime: enrichedRecipeData['Cooking Time']?.toString() ?? '30 min',
          servings: int.tryParse(enrichedRecipeData['Serving']?.toString() ?? '1') ?? 1,
          ingredients: ingredientsList,
          fullRecipeData: enrichedRecipeData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    if (!authService.isAuthenticated) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final weekDates = _generateWeekDates();
    final selectedDateRecipes = _getRecipesForDate(_selectedDate);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _selectedDate,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Date selector
            Container(
              height: 70,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: weekDates.length,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) {
                  final date = weekDates[index];
                  final isSelected = date == _selectedDate;
                  final dateParts = date.split(' ');
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDate = date;
                        _selectedDateIndex = index;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFF7A4A) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            dateParts.length >= 2 ? dateParts[0] : '',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : Colors.black54,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            dateParts.length >= 2 ? dateParts[1] : '',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? Colors.white : Colors.black54,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF7A4A),
                      ),
                    )
                  : selectedDateRecipes.isEmpty
                      ? _buildEmptyState()
                      : _buildRecipeList(selectedDateRecipes),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height - 
                     MediaQuery.of(context).padding.top - 
                     MediaQuery.of(context).padding.bottom - 
                     140, // Account for AppBar and date selector
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 24,
              vertical: MediaQuery.of(context).padding.bottom + 20,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.restaurant_menu,
                  size: MediaQuery.of(context).size.width * 0.15, // Responsive icon size
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 24),
                Text(
                  'No recipes for this date',
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.045, // Responsive font size
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Try generating new recipes',
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.035, // Responsive font size
                    color: Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.6, // Responsive button width
                  child: ElevatedButton(
                    onPressed: _generateWeeklyRecipes,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7A4A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Text(
                      'Generate Recipes',
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.04, // Responsive font size
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecipeList(List<Map<String, dynamic>> recipes) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 80, // Account for safe area and navigation
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breakfast section
          if (recipes.any((r) => r['Meal_Type']?.toString() == 'Breakfast')) ...[
            _buildMealSection(
              'Breakfast',
              recipes.where((r) => r['Meal_Type']?.toString() == 'Breakfast').toList(),
            ),
            const SizedBox(height: 20),
          ],
          
          // Lunch section
          if (recipes.any((r) => r['Meal_Type']?.toString() == 'Lunch')) ...[
            _buildMealSection(
              'Lunch',
              recipes.where((r) => r['Meal_Type']?.toString() == 'Lunch').toList(),
            ),
            const SizedBox(height: 20),
          ],
          
          // Snacks section
          if (recipes.any((r) => r['Meal_Type']?.toString() == 'Snacks')) ...[
            _buildMealSection(
              'Snacks',
              recipes.where((r) => r['Meal_Type']?.toString() == 'Snacks').toList(),
            ),
            const SizedBox(height: 20),
          ],
          
          // Dinner section
          if (recipes.any((r) => r['Meal_Type']?.toString() == 'Dinner')) ...[
            _buildMealSection(
              'Dinner',
              recipes.where((r) => r['Meal_Type']?.toString() == 'Dinner').toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMealSection(String mealType, List<Map<String, dynamic>> recipes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          mealType,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        ...recipes.map((recipe) => _buildRecipeCard(recipe)).toList(),
      ],
    );
  }

  Widget _buildRecipeCard(dynamic recipe) {
    // Debug print to see what fields are available
    print("🔍 DEBUG: Recipe data keys: ${recipe.keys}");
    print("🔍 DEBUG: Looking for image in recipe: ${recipe['image_url']}");
    print("🔍 DEBUG: Recipe data: $recipe");
    
    // Extract cuisine from recipe data or use fallback
    final cuisine = recipe['Cuisine']?.toString() ?? 
                   recipe['cuisine']?.toString() ?? 
                   recipe['Cuisine_Preference']?.toString() ?? 
                   recipe['Meal_Type']?.toString() ?? 
                   'Indian'; // Fallback to match current behavior
    
    print("🍽️ DEBUG: Extracted cuisine: $cuisine");
    
    return GestureDetector(
      onTap: () => _navigateToRecipeDetail(recipe),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe image with refresh button
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.2, // Responsive height (20% of screen height)
                    width: double.infinity,
                    color: Colors.grey.shade200,
                    child: recipe['image_url'] != null && recipe['image_url'].toString().isNotEmpty
                        ? Image.network(
                            recipe['image_url'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              print("❌ DEBUG: Failed to load image: ${recipe['image_url']}, error: $error");
                              return Container(
                                color: Colors.grey.shade300,
                                child: const Center(
                                  child: Icon(Icons.restaurant, size: 48, color: Colors.grey),
                                ),
                              );
                            },
                          )
                        : Container(
                            color: Colors.grey.shade300,
                            child: const Center(
                              child: Icon(Icons.restaurant, size: 48, color: Colors.grey),
                            ),
                          ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        // Refresh this specific recipe
                        _generateWeeklyRecipes();
                      },
                      icon: const Icon(Icons.refresh, size: 18),
                    ),
                  ),
                ),
                // AI and cuisine tags
                Positioned(
                  top: 12,
                  left: 12,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Gen-AI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          cuisine,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Recipe details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          recipe['Recipe Name']?.toString() ?? 'Untitled Recipe',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          // Toggle favorite
                        },
                        icon: const Icon(
                          Icons.favorite_border,
                          color: Colors.grey,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    recipe['Short Description']?.toString() ?? '',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        recipe['Cooking Time']?.toString() ?? 'N/A',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
