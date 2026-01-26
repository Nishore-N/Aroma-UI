// lib/ui/screens/preferences/cooking_preference_screen.dart
import 'package:flutter/material.dart';
import '../recipes/recipe_list_screen.dart';
import '../../widgets/recipe_generation_animation.dart';
import '../../../data/services/home_recipe_service.dart';

class CookingPreferenceScreen extends StatefulWidget {
  final List<Map<String, dynamic>> ingredients;

  const CookingPreferenceScreen({
    super.key,
    required this.ingredients,
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
  // NON-VEG IDENTIFICATION LIST
  // ---------------------------
  final List<String> _nonVegItems = [
    "chicken",
    "mutton",
    "fish",
    "egg",
    "eggs",
    "prawn",
    "shrimp",
    "beef",
    "pork",
    "lamb"
  ];

  bool _containsNonVeg(List<String> ingredients) {
    return ingredients.any(
      (item) =>
          _nonVegItems.any((nv) => item.toLowerCase().contains(nv)),
    );
  }

  // ---------------------------
  // DIET–CONFLICT POPUP HANDLER
  // ---------------------------
  Future<int?> _showDietConflictDialog() {
    return showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Diet Conflict Found ⚠️"),
        content: const Text(
          "Your selected diet is Vegetarian, but some ingredients appear to be Non-Vegetarian.\n\nChoose how you want to continue:",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 1),
            child: const Text("Remove Non-Veg"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 2),
            child: const Text("Change Diet"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 0),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

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

  final Map<String, bool> _expanded = {};
  final Map<String, String> _selectedPerSection = {};

  @override
  void initState() {
    super.initState();

    // ✅ create safe copy
    _workingIngredients =
        List<Map<String, dynamic>>.from(widget.ingredients);

    options.forEach((k, v) {
      _expanded[k] = false;
      _selectedPerSection[k] = v.first;
    });
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
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 120),
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
    final isExpanded = _expanded[title]!;
    final visibleItems = isExpanded ? items : items.take(4).toList();
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
                .map((item) => _chip(title, item, item == selectedItem))
                .toList(),
          ),
          if (items.length > 4)
            GestureDetector(
              onTap: () => setState(() => _expanded[title] = !isExpanded),
              child: Text(
                isExpanded ? "View Less" : "View More",
                style: const TextStyle(
                  color: Color(0xFFFF6A45),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _chip(String section, String text, bool selected) {
    return GestureDetector(
      onTap: () => setState(() => _selectedPerSection[section] = text),
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

        String selectedDiet =
            _selectedPerSection["Dietary Restrictions"] ?? "";

        if (selectedDiet == "Vegetarian" &&
            _containsNonVeg(ingredientNames)) {
          final choice = await _showDietConflictDialog();
          if (choice == 0) return;
          if (choice == 1) {
            _workingIngredients.removeWhere((ing) =>
                _nonVegItems.any((nv) =>
                    ing["item"].toString().toLowerCase().contains(nv)));
          } else if (choice == 2) {
            setState(() {
              _selectedPerSection["Dietary Restrictions"] =
                  "Non- Vegetarian";
            });
          }
        }

        // Show animation first
        setState(() {
          _isGenerating = true;
        });

        try {
          final pref = {
            "Cuisine_Preference": _selectedPerSection["Cuisine Preference"],
            "Dietary_Restrictions": _selectedPerSection["Dietary Restrictions"],
            "Cookware_Available": [_selectedPerSection["Cookware & Utensils"]],
            "Meal_Type": [_selectedPerSection["Meal Type"]],
            "Cooking_Time": _selectedPerSection["Cooking Time"],
            "Serving": servingCount,
            "Ingredients_Available": _workingIngredients,
          };

          // Generate recipes during animation
          final recipes = await _homeRecipeService.generateWeeklyRecipes(pref);
          
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
