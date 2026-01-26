import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../preferences/cooking_preference_screen.dart';
import '../home/generate_recipe_screen.dart';
import '../../../state/pantry_state.dart';
import '../../../core/utils/category_engine.dart';
import '../../../data/services/pantry_list_service.dart';
import '../../../data/services/home_recipe_service.dart';
import '../../../core/utils/item_image_resolver.dart';
import '../../../ui/widgets/ingredient_row.dart';
import '../../widgets/cooking_loader.dart';


const Color kAccent = Color(0xFFFF7A4A);

class SelectIngredientsScreen extends StatefulWidget {
  const SelectIngredientsScreen({super.key});

  @override
  State<SelectIngredientsScreen> createState() =>
      _SelectIngredientsScreenState();
}

class _SelectIngredientsScreenState extends State<SelectIngredientsScreen> {
  // ───────────────── CATEGORIES ─────────────────
  final List<String> _categories = [
    'All',
    'Fruits & Vegetables',
    'Dairy & Alternatives',
    'Eggs, Meat & Fish',
    'Grains & Staples',
    'Spices & Masalas',
    'Oils & Condiments',
    'Ready-to-Eat',
    'Nuts & Dry Fruits',
    'Snacks & Bakery',
    'Beverages',
    'Others',
  ];

  String _selectedCategory = 'All';
  bool _isLoading = true;
  bool _isGenerating = false;
  List<_Ingredient> _allIngredients = [];
  Set<String> _selectedIngredients = {};
  final PantryListService _pantryListService = PantryListService();

  @override
  void initState() {
    super.initState();
    _loadPantryIngredients();
  }

  Future<void> _loadPantryIngredients() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print("🔍 DEBUG: Starting to load pantry ingredients from REMOTE server...");
      
      // Load from remote server using PantryListService
      final remotePantryItems = await _pantryListService.fetchPantryItems();
      print("🔍 DEBUG: Got ${remotePantryItems.length} items from remote server");
      print("🔍 DEBUG: Remote items: ${remotePantryItems.map((e) => e['name']).toList()}");
      
      // Convert remote pantry ingredients to _Ingredient objects with image URLs
      final ingredients = remotePantryItems.map((item) => _Ingredient(
        name: item['name']?.toString() ?? '',
        category: CategoryEngine.getCategory(item['name']?.toString() ?? ''),
        subtitle: CategoryEngine.getCategory(item['name']?.toString() ?? ''),
        icon: _getIconForIngredient(item['name']?.toString() ?? ''),
        imageUrl: item['imageUrl'] as String?, // Include imageUrl from remote
      )).toList();

      setState(() {
        _allIngredients = ingredients;
        _isLoading = false;
      });

      print("🔍 DEBUG: Loaded ${ingredients.length} pantry ingredients from REMOTE server for selection");
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("❌ Error loading REMOTE pantry ingredients: $e");
      
      // Fallback: Try loading from local PantryState as backup
      try {
        print("🔄 FALLBACK: Trying to load from local PantryState...");
        final pantryState = Provider.of<PantryState>(context, listen: false);
        await pantryState.loadPantry();
        
        final fallbackIngredients = pantryState.items.map((item) => _Ingredient(
          name: item.name,
          category: CategoryEngine.getCategory(item.name),
          subtitle: CategoryEngine.getCategory(item.name),
          icon: _getIconForIngredient(item.name),
          imageUrl: item.imageUrl,
        )).toList();

        setState(() {
          _allIngredients = fallbackIngredients;
          _isLoading = false;
        });
        
        print("🔍 DEBUG: Loaded ${fallbackIngredients.length} ingredients from LOCAL fallback");
      } catch (fallbackError) {
        print("❌ Fallback also failed: $fallbackError");
        setState(() {
          _allIngredients = [];
          _isLoading = false;
        });
      }
    }
  }

  String _getIconForIngredient(String ingredient) {
    final lower = ingredient.toLowerCase();
    if (lower.contains('apple')) return '🍎';
    if (lower.contains('banana')) return '🍌';
    if (lower.contains('orange')) return '🍊';
    if (lower.contains('pomegranate') || lower.contains('anar')) return '🍎';
    if (lower.contains('carrot')) return '🥕';
    if (lower.contains('tomato')) return '🍅';
    if (lower.contains('onion')) return '🧅';
    if (lower.contains('potato')) return '🥔';
    if (lower.contains('garlic')) return '🧄';
    if (lower.contains('ginger')) return '🫚';
    if (lower.contains('milk')) return '🥛';
    if (lower.contains('cheese')) return '🧀';
    if (lower.contains('yogurt') || lower.contains('curd')) return '🥛';
    if (lower.contains('egg')) return '🥚';
    if (lower.contains('chicken')) return '🍗';
    if (lower.contains('fish')) return '🐟';
    if (lower.contains('bread')) return '🍞';
    if (lower.contains('nuts') || lower.contains('almond') || lower.contains('cashew')) return '🥜';
    if (lower.contains('rice') || lower.contains('atta') || lower.contains('flour')) return '🌾';
    if (lower.contains('oil') || lower.contains('ghee')) return '🫒';
    if (lower.contains('spice') || lower.contains('powder') || lower.contains('masala')) return '🌶️';
    return '🥗'; // Default icon
  }

  void _toggleIngredientSelection(String ingredientName) {
    setState(() {
      if (_selectedIngredients.contains(ingredientName)) {
        _selectedIngredients.remove(ingredientName);
      } else {
        _selectedIngredients.add(ingredientName);
      }
    });
  }

  void _selectAllIngredients() {
    setState(() {
      _selectedIngredients = Set.from(_allIngredients.map((ing) => ing.name));
    });
  }

  void _deselectAllIngredients() {
    setState(() {
      _selectedIngredients.clear();
    });
  }

  List<_Ingredient> get _filteredIngredients {
    if (_selectedCategory == 'All') {
      return _allIngredients;
    }
    return _allIngredients.where((ing) => ing.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: kAccent),
        ),
      );
    }

    // Show CookingLoader when generating recipes
    if (_isGenerating) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: CookingLoader(
          message: "generating your weekly recipes...",
        ),
      );
    }

    final ingredients = _filteredIngredients;
    print("🔍 DEBUG: Building UI with ${ingredients.length} filtered ingredients");
    print("🔍 DEBUG: Selected category: $_selectedCategory");
    print("🔍 DEBUG: Total ingredients in _allIngredients: ${_allIngredients.length}");

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
          'Select Ingredients',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              // search action – optional
            },
            icon: const Icon(Icons.search, color: Colors.black),
          ),
        ],
      ),

      // BODY
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // ───────── CATEGORY CHIPS ROW ─────────
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final bool selected = cat == _selectedCategory;

                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedCategory = cat);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? kAccent : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color:
                            selected ? kAccent : Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // ───────── SELECT ALL/DESELECT ALL ROW ─────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${_selectedIngredients.length} selected',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _selectedIngredients.length == _allIngredients.length
                      ? _deselectAllIngredients
                      : _selectAllIngredients,
                  child: Text(
                    _selectedIngredients.length == _allIngredients.length
                        ? 'Deselect All'
                        : 'Select All',
                    style: const TextStyle(
                      color: kAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ───────── LIST OF INGREDIENTS ─────────
          Expanded(
            child: ingredients.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.kitchen_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No ingredients found in your pantry',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add ingredients to your pantry first',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    itemCount: ingredients.length,
                    itemBuilder: (context, index) {
                      final item = ingredients[index];
                      final bool isChecked = _selectedIngredients.contains(item.name);

                      return Row(
                        children: [
                          // Checkbox for selection
                          Padding(
                            padding: const EdgeInsets.only(left: 16, right: 8),
                            child: Checkbox(
                              value: isChecked,
                              onChanged: (bool? value) {
                                _toggleIngredientSelection(item.name);
                              },
                              activeColor: kAccent,
                            ),
                          ),
                          
                          // IngredientRow-like content
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              margin: const EdgeInsets.only(right: 8, bottom: 6, top: 6),
                              child: Row(
                                children: [
                                  // Dynamic ingredient image/emoji - using ItemImageResolver for consistency
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: ItemImageResolver.getImageWidget(
                                      item.name,
                                      size: 50,
                                      imageUrl: item.imageUrl, // Pass imageUrl to let resolver handle it
                                    ),
                                  ),

                                  const SizedBox(width: 14),

                                  // Name + category text
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 17,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.subtitle,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.black.withOpacity(0.55),
                                          ),
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
                    },
                  ),
          ),
        ],
      ),

      // ───────── BOTTOM NEXT BUTTON ─────────
      bottomNavigationBar: SafeArea(
        child: Container(
          padding:
              const EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 10),
          child: SizedBox(
            height: 56,
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kAccent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: () async {
                if (_selectedIngredients.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select at least one ingredient'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                // Show loading animation first
                setState(() {
                  _isGenerating = true;
                });
                
                final selectedList = _selectedIngredients.toList();
                print("🔍 DEBUG: Selected ingredients for recipe generation: $selectedList");
                
                // Generate recipes in background during animation
                List<Map<String, dynamic>> generatedRecipes = [];
                try {
                  // Create request data for weekly recipe generation
                  final requestData = {
                    "Cuisine_Preference": "Indian",
                    "Dietary_Restrictions": "Vegetarian",
                    "Cookware_Available": ["Microwave Oven"],
                    "Meal_Type": ["Breakfast", "Lunch", "Snacks", "Dinner"],
                    "Cooking_Time": "< 30 min",
                    "Serving": "1",
                    "Ingredients_Available": selectedList,
                  };
                  
                  print('📤 [SelectIngredients] Sending request with ${selectedList.length} ingredients');
                  
                  // Import HomeRecipeService to generate recipes
                  final homeRecipeService = HomeRecipeService();
                  final dynamicResult = await homeRecipeService.generateWeeklyRecipes(requestData);
                  generatedRecipes = List<Map<String, dynamic>>.from(dynamicResult);
                  print('✅ [SelectIngredients] Generated ${generatedRecipes.length} recipes during animation');
                } catch (e) {
                  print('❌ [SelectIngredients] Recipe generation failed: $e');
                  // Still navigate even if generation fails, let GenerateRecipeScreen handle it
                }
                
                // Wait for remaining animation time if generation completed quickly
                await Future.delayed(const Duration(milliseconds: 500));
                
                if (mounted) {
                  // Reset generating state and navigate with pre-generated recipes
                  setState(() {
                    _isGenerating = false;
                  });
                  
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GenerateRecipeScreen(
                        usePantryIngredients: true,
                        pantryIngredients: selectedList,
                        preGeneratedRecipes: generatedRecipes,
                      ),
                    ),
                  );
                }
              },
              child: Text(
                _selectedIngredients.isEmpty 
                    ? 'Select Ingredients' 
                    : 'Generate Recipes (${_selectedIngredients.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build emoji fallback
  Widget _buildEmojiFallback(String emoji) {
    return CircleAvatar(
      radius: 32,
      backgroundColor: const Color(0xFFFFF3E6),
      child: Text(
        emoji,
        style: const TextStyle(fontSize: 32),
      ),
    );
  }
}

// ───────────────── MODEL ─────────────────
class _Ingredient {
  final String name;
  final String category;
  final String subtitle;
  final String icon;
  final String? imageUrl; // Add imageUrl field

  const _Ingredient({
    required this.name,
    required this.category,
    required this.subtitle,
    required this.icon,
    this.imageUrl, // Add to constructor
  });
}
