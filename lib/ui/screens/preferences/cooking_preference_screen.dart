import 'package:flutter/material.dart';
import '../recipes/recipe_list_screen.dart';
import '../../widgets/recipe_generation_animation.dart';
import '../../../data/services/home_recipe_service.dart';
import '../../../data/services/preference_api_service.dart';
import '../home/generate_recipe_screen.dart';

class CookingPreferenceScreen extends StatefulWidget {
  final List<Map<String, dynamic>> ingredients;
  final bool isWeekly;

  const CookingPreferenceScreen({
    super.key,
    required this.ingredients,
    this.isWeekly = false,
  });

  @override
  State<CookingPreferenceScreen> createState() =>
      _CookingPreferenceScreenState();
}

class _CookingPreferenceScreenState extends State<CookingPreferenceScreen> {
  int servingCount = 4;
  bool _isGenerating = false;
  final HomeRecipeService _homeRecipeService = HomeRecipeService();

  // ✅ LOCAL MUTABLE COPY (IMPORTANT FIX)
  late List<Map<String, dynamic>> _workingIngredients;



  // ---------------------------
  // PREFERENCE OPTIONS
  // ---------------------------
  final Map<String, List<String>> options = {
    "Meal Type": ["Breakfast", "Lunch", "Dinner", "Snack", "Dessert"],
    "Dietary Restrictions": [
      "Vegetarian",
      "Non- Vegetarian",
      "Vegan",
      "Eggetarian",
      "Keto"
    ],
    "Cookware & Utensils": ["Pan", "Pot", "Oven", "Pressure Cooker"],
    "Cooking Time": ["5 - 10 minutes", "15 minutes", "30 minutes", "45 minutes"],
    "Cuisine Preference": [
      "North Indian",
      "South Indian",
      "Chinese",
      "Italian",
      "Continental"
    ],
  };


  final Map<String, String> _selectedPerSection = {};
  final Set<String> _selectedMealTypes = {}; // For weekly multi-select

  @override
  void initState() {
    super.initState();

    // ✅ create safe copy
    _workingIngredients =
        List<Map<String, dynamic>>.from(widget.ingredients);

    options.forEach((k, v) {
      _selectedPerSection[k] = v.first;
    });

    // Pre-select all meal types for weekly mode
    if (widget.isWeekly) {
      _selectedMealTypes.addAll(["Breakfast", "Lunch", "Dinner"]);
      debugPrint('🍽️ [CookingPreference] Pre-selected meal types: $_selectedMealTypes');
    }

    if (widget.isWeekly) {
      _selectedPerSection["Cooking Time"] = "5 - 10 minutes";
      _selectedPerSection["Serving"] = "4";
    }
  }

  // ---------------------------
  // UI BUILD
  // ---------------------------
  @override
  Widget build(BuildContext context) {
    // Show animation when generating
    if (_isGenerating) {
      return const RecipeGenerationAnimation(
        message: "generating your recipes",
        primaryColor: Color(0xFFFF6A45),
        secondaryColor: Color(0xFFFFD93D),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _bottomSection(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _backButton(),
              const SizedBox(height: 18),
              _title("Cooking Preference"),
              const SizedBox(height: 22),
              for (final section in options.keys)
                _buildSection(section, options[section]!),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------
  // BOTTOM SECTION
  // ---------------------------
  Widget _bottomSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Serving needed",
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          _servingBox(),
          const SizedBox(height: 18),
          _generateBtn(),
        ],
      ),
    );
  }

  Widget _backButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        height: 42,
        width: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black.withOpacity(0.15)),
        ),
        child: const Icon(Icons.arrow_back, size: 20),
      ),
    );
  }

  Widget _title(String text) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 26),
    );
  }

  // ---------------------------
  // SECTION BUILDER
  // ---------------------------
  Widget _buildSection(String title, List<String> items) {
    // Show all items by default
    final visibleItems = items;
    final selectedItem = _selectedPerSection[title]!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(title),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: visibleItems
                .map((item) {
                  final bool isSelected = widget.isWeekly && title == "Meal Type" 
                      ? _selectedMealTypes.contains(item)
                      : item == selectedItem;
                  
                  if (widget.isWeekly && title == "Meal Type") {
                    debugPrint('🍽️ [CookingPreference] Item: $item, Contains: ${_selectedMealTypes.contains(item)}, Selected: $isSelected');
                  }
                  
                  return _chip(title, item, isSelected);
                })
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _chip(String section, String text, bool selected) {
    return GestureDetector(
      onTap: widget.isWeekly && section == "Meal Type" 
        ? null // Disable tap in weekly mode - all meal types are pre-selected
        : () => setState(() => _selectedPerSection[section] = text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFE5DA) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFFFF6A45) : Colors.black12,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected ? const Color(0xFFFF6A45) : Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // ---------------------------
  // SERVING COUNTER
  // ---------------------------
  Widget _servingBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFFF6A45), width: 1.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: _stepper("-", () {
              setState(() {
                servingCount = servingCount > 1 ? servingCount - 1 : 1;
              });
            }),
          ),
          const SizedBox(width: 14),
          Text(
            "$servingCount",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _stepper("+", () => setState(() => servingCount++)),
          ),
        ],
      ),
    );
  }

  Widget _stepper(String text, VoidCallback action) {
    return GestureDetector(
      onTap: action,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFFFEFE6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFF6A45),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------
  // GENERATE BUTTON
  // ---------------------------
  Widget _generateBtn() {
    return GestureDetector(
      onTap: () async {
        List<String> ingredientNames =
            _workingIngredients.map((e) => e["item"].toString()).toList();

        // Show animation first
        setState(() {
          _isGenerating = true;
        });

        try {
          final pref = {
            "Cuisine_Preference": _selectedPerSection["Cuisine Preference"],
            "Dietary_Restrictions": _selectedPerSection["Dietary Restrictions"],
            "Cookware_Available": [_selectedPerSection["Cookware & Utensils"]],
            "Meal_Type": widget.isWeekly ? ["Breakfast", "Lunch", "Dinner"] : [_selectedPerSection["Meal Type"]],
            "Cooking_Time": _selectedPerSection["Cooking Time"],
            "Serving": servingCount.toString(),
            "Ingredients_Available": ingredientNames,
          };

          if (widget.isWeekly) {
            // Call weekly generation API
            final weeklyData = await _homeRecipeService.generateWeeklyRecipes(pref);
            
            if (mounted) {
              setState(() {
                _isGenerating = false;
              });
              
              if (weeklyData.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GenerateRecipeScreen(
                      preGeneratedRecipes: List<Map<String, dynamic>>.from(weeklyData),
                      usePantryIngredients: true,
                      pantryIngredients: ingredientNames,
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No recipes generated for weekly plan')),
                );
              }
            }
            return;
          }

          // Generate recipes during animation (Single recipe generation)
          final recipesData = await PreferenceApiService.generateRecipes(_workingIngredients, pref);
          debugPrint("🧪 [UI] API Response received in UI: $recipesData");
          
          final recipes = List<Map<String, dynamic>>.from(recipesData['data']?['recipes'] ?? []);
          
          // Wait for animation to show
          await Future.delayed(const Duration(seconds: 2));
          
          // Reset generating state and navigate to recipe detail
          if (mounted) {
            setState(() {
              _isGenerating = false;
            });
            
            // Navigate to first recipe detail instead of recipe list
            if (recipes.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RecipeListScreen(
                    ingredients: _workingIngredients,
                    preferences: pref,
                    initialRecipes: recipes,
                  ),
                ),
              );
            }
          }
        } catch (e) {
          // Reset generating state on error
          if (mounted) {
            setState(() {
              _isGenerating = false;
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to generate recipes: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFFFF6A45),
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Center(
          child: Text(
            "Generate Recipe ✨",
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 17,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------
// SECTION TITLE
// ---------------------------
class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
    );
  }
}
