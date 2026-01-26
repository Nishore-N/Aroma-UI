import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/extreme_spring_physics.dart';
import 'ingredient_section.dart';
import 'cookware_section.dart';
import 'preparation_section.dart';
import 'review_section.dart';
import 'similar_recipes_section.dart';
import '../ingredients_needed/ingredients_needed_screen.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/recipe_detail_service.dart';
import '../../../state/pantry_state.dart';
import 'package:cached_network_image/cached_network_image.dart';

class RecipeDetailScreen extends StatefulWidget {
  final String image;
  final String title;
  final List<Map<String, dynamic>> ingredients;
  final String cuisine;
  final String cookTime;
  final int servings;
  final Map<String, dynamic> fullRecipeData; // Complete backend data

  const RecipeDetailScreen({
    super.key,
    required this.image,
    required this.title,
    required this.ingredients,
    required this.cuisine,
    required this.cookTime,
    required this.servings,
    required this.fullRecipeData,
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  bool isExpanded = false;
  bool isFavorite = false;
  bool isSaved = false;
  int servings = 4;
  String cookTime = ""; 

  final ApiClient _apiClient = ApiClient();

  List<String> _cookingSteps = [];
  List<Map<String, dynamic>> _cookingStepsDetailed = [];
  List<Map<String, dynamic>> _ingredientData = [];
  List<Map<String, dynamic>> _reviewData = [];
  List<Map<String, dynamic>> _similarRecipeData = [];
  List<String> _cookwareItems = [];
  Map<String, dynamic> _nutrition = {}; 
  String _description = ""; 

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _ingredientsKey = GlobalKey();
  final GlobalKey _cookwareKey = GlobalKey();
  final GlobalKey _preparationKey = GlobalKey();

  int selectedTab = 0;

  @override
  void initState() {
    super.initState();
    servings = widget.servings;
    _ingredientData = widget.ingredients;
    cookTime = widget.cookTime; 
    
    debugPrint('🔍 RecipeDetailScreen initState called');
    
    if (cookTime == "0" || cookTime.isEmpty) {
      _extractCookingTimeFromBackend();
    }
    
    _extractBackendData();
  }

  void _extractCookingTimeFromBackend() {
    try {
      final recipeData = widget.fullRecipeData;
      
      final possibleTimeFields = [
        "Cooking Time", "cooking_time", "total_time", "totalTime", 
        "cook_time", "prep_time", "preparation_time", "time"
      ];
      
      String extractedTime = "0";
      for (final field in possibleTimeFields) {
        if (recipeData[field] != null && recipeData[field].toString().isNotEmpty) {
          extractedTime = recipeData[field].toString();
          break;
        }
      }
      
      final numberMatch = RegExp(r'\d+').firstMatch(extractedTime);
      if (numberMatch != null) {
        final cookTimeMinutes = numberMatch.group(0) ?? "0";
        if (cookTimeMinutes != "0") {
          setState(() {
            cookTime = '$cookTimeMinutes min';
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Error extracting cooking time: $e');
    }
  }

  void _extractBackendData() {
    try {
      final recipeData = widget.fullRecipeData;
      
      setState(() {
        _description = recipeData["description"]?.toString() ?? "";
        
        _nutrition = recipeData["nutrition"] ?? {};
        
        if (_nutrition.isEmpty) {
          _nutrition = recipeData["nutritional_info"] ?? {};
        }
        if (_nutrition.isEmpty) {
          _nutrition = recipeData["nutrients"] ?? {};
        }
        
        if (_nutrition.isEmpty) {
          _nutrition = {
            "calories": recipeData["calories"] ?? recipeData["Calories"] ?? 0,
            "protein": recipeData["protein"] ?? recipeData["Protein"] ?? 0,
            "carbs": recipeData["carbs"] ?? recipeData["Carbohydrates"] ?? recipeData["carbohydrates"] ?? 0,
            "fats": recipeData["fats"] ?? recipeData["Fat"] ?? recipeData["total_fat"] ?? 0,
            "fiber": recipeData["fiber"] ?? recipeData["Fiber"] ?? 0,
          };
        }
        
        if (_nutrition.isEmpty || (_nutrition["calories"] == 0 && _nutrition["protein"] == 0)) {
          final ingredients = recipeData["ingredients_with_quantity"] ?? recipeData["ingredients"] ?? [];
          double totalCalories = 0;
          double totalProtein = 0;
          double totalCarbs = 0;
          double totalFats = 0;
          double totalFiber = 0;
          
          if (ingredients is List) {
            for (var ingredient in ingredients) {
              if (ingredient is Map && ingredient["macros"] is Map) {
                final macros = ingredient["macros"] as Map<String, dynamic>;
                
                totalCalories += (macros["calories_kcal"] as num?)?.toDouble() ?? 0;
                totalProtein += (macros["protein_g"] as num?)?.toDouble() ?? 0;
                totalCarbs += (macros["carbohydrates_g"] as num?)?.toDouble() ?? 0;
                totalFats += (macros["fat_g"] as num?)?.toDouble() ?? 0;
                totalFiber += (macros["fiber_g"] as num?)?.toDouble() ?? 0;
              }
            }
          }
          
          if (totalCalories > 0 || totalProtein > 0) {
            _nutrition = {
              "calories": totalCalories.round(),
              "protein": totalProtein.toStringAsFixed(1),
              "carbs": totalCarbs.toStringAsFixed(1),
              "fats": totalFats.toStringAsFixed(1),
              "fiber": totalFiber.toStringAsFixed(1),
            };
          }
        }
        
        if (_nutrition.isEmpty || (_nutrition["calories"] == 0 && _nutrition["protein"] == 0)) {
          _nutrition = {
            "calories": 250,
            "protein": 12,
            "carbs": 35,
            "fats": 8,
            "fiber": 4,
          };
        }
        
        _cookingStepsDetailed = List<Map<String, dynamic>>.from(recipeData["cooking_steps"] ?? []);
        
        if (_cookingStepsDetailed.isEmpty) {
          final allIngredients = List<Map<String, dynamic>>.from(recipeData["ingredients_with_quantity"] ?? recipeData["ingredients"] ?? []);
          _cookingStepsDetailed = [
            {
              'instruction': 'Prepare all ingredients',
              'ingredients_used': allIngredients,
              'tips': ['Wash and clean all ingredients before use'],
            },
            {
              'instruction': 'Cook according to recipe instructions',
              'ingredients_used': allIngredients,
              'tips': ['Follow cooking times carefully'],
            }
          ];
        } else {
          final allIngredients = List<Map<String, dynamic>>.from(recipeData["ingredients_with_quantity"] ?? recipeData["ingredients"] ?? []);
          
          _cookingStepsDetailed = _cookingStepsDetailed.asMap().entries.map((entry) {
            final stepIndex = entry.key;
            final step = entry.value;
            final instruction = (step['instruction'] ?? '').toString().toLowerCase();
            
            if (!step.containsKey('ingredients_used')) {
              
              List<Map<String, dynamic>> stepIngredients = [];
              
              for (var ingredient in allIngredients) {
                final ingredientName = (ingredient['item'] ?? ingredient['name'] ?? '').toString().toLowerCase();
                if (instruction.contains(ingredientName) || 
                    instruction.contains(ingredientName.replaceAll(' ', '')) ||
                    instruction.contains(ingredientName.split(' ')[0])) {
                  stepIngredients.add(ingredient);
                }
              }
              
              if (stepIngredients.isEmpty) {
                final totalSteps = _cookingStepsDetailed.length;
                final ingredientsPerStep = (allIngredients.length / totalSteps).ceil();
                final startIndex = stepIndex * ingredientsPerStep;
                final endIndex = (startIndex + ingredientsPerStep).clamp(0, allIngredients.length);
                
                if (startIndex < allIngredients.length) {
                  stepIngredients = allIngredients.sublist(startIndex, endIndex);
                }
              }
              
              if (stepIngredients.isEmpty && allIngredients.isNotEmpty) {
                stepIngredients = [allIngredients[stepIndex % allIngredients.length]];
              }
              
              step['ingredients_used'] = stepIngredients;
            }
            
            return step;
          }).toList();
        }
        
        _cookingSteps = _cookingStepsDetailed
            .map((e) => (e['instruction'] ?? '').toString())
            .where((s) => s.trim().isNotEmpty)
            .toList();
        
        final tags = recipeData["tags"] ?? {};
        _cookwareItems = List<String>.from(tags["cookware"] ?? []);
        
        if (_cookwareItems.isEmpty) {
          _cookwareItems = ['Gas Stove', 'Pan', 'Blender'];
        }
        
        final backendIngredients = List<Map<String, dynamic>>.from(recipeData["ingredients_with_quantity"] ?? recipeData["ingredients"] ?? []);
        _ingredientData = backendIngredients.isNotEmpty ? backendIngredients : widget.ingredients;
        
        _reviewData = _generateSampleReviews(widget.title);
        
      });
      
    } catch (e) {
      debugPrint('❌ Error extracting backend data: $e');
      setState(() {
        _cookingSteps = [];
        _cookingStepsDetailed = [];
      });
    }
  }

  void _scrollTo(GlobalKey key) {
    Scrollable.ensureVisible(
      key.currentContext!,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  List<Map<String, dynamic>> _generateSampleReviews(String recipeName) {
    return [
      {
        "name": "Sarah Johnson",
        "rating": 5,
        "comment": "Absolutely loved this $recipeName! The flavors were perfectly balanced and it was so easy to make. Will definitely be making this again.",
        "timeAgo": "2 days ago",
        "isAI": false,
      },
      {
        "name": "Mike Chen",
        "rating": 4,
        "comment": "Great recipe for $recipeName! I added a little extra spice and it turned out amazing. My family loved it.",
        "timeAgo": "1 week ago",
        "isAI": false,
      },
      {
        "name": "Emily Davis",
        "rating": 5,
        "comment": "This $recipeName recipe is now my go-to! Perfect for dinner parties and always gets compliments. Thank you for sharing!",
        "timeAgo": "2 weeks ago",
        "isAI": false,
      }
    ];
  }

  Widget _content() {
    return Consumer<PantryState>(
      builder: (_, pantryState, __) {
        final pantryItems = pantryState.pantryItems;

        final availableIngredients = _ingredientData.where((ingredient) {
          final name = ingredient['item']?.toString().toLowerCase() ?? '';
          return pantryItems.any((p) =>
              p.name.toLowerCase() == name && p.quantity > 0);
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(widget.title,
                style:
                    const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _RecipeInfoItem(icon: Icons.restaurant, label: widget.cuisine),
                _RecipeInfoItem(
                    icon: Icons.local_fire_department,
                    label: '${_nutrition["calories"]?.toString() ?? "--"} cal'),
                _RecipeInfoItem(icon: Icons.access_time, label: cookTime.isEmpty ? "N/A" : cookTime),
                _RecipeInfoItem(icon: Icons.people, label: servings.toString()),
              ],
            ),

            const SizedBox(height: 22),

            AnimatedCrossFade(
              firstChild: Text(
                _description.isEmpty ? "No description available" : _description,
                style: const TextStyle(color: Colors.black),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              secondChild: Text(_description, style: const TextStyle(color: Colors.black)),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),

            GestureDetector(
              onTap: () => setState(() => isExpanded = !isExpanded),
              child: const Text(
                "Read more..",
                style: TextStyle(
                    color: Colors.orange, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 30),

            const Text("Nutrition per serving",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),

            const SizedBox(height: 20),

            Wrap(
              spacing: 20,
              runSpacing: 18,
              children: [
                _NutritionTile(
                    icon: Icons.grass,
                    label: '${_nutrition["carbs"]?.toString() ?? "--"}g'),
                _NutritionTile(
                    icon: Icons.fitness_center,
                    label: '${_nutrition["protein"]?.toString() ?? "--"}g'),
                _NutritionTile(
                    icon: Icons.local_fire_department,
                    label: '${_nutrition["calories"]?.toString() ?? "--"} cal'),
                _NutritionTile(
                    icon: Icons.lunch_dining,
                    label: '${_nutrition["fats"]?.toString() ?? "--"}g'),
                _NutritionTile(
                    icon: Icons.eco,
                    label: '${_nutrition["fiber"]?.toString() ?? "--"}g'),
              ],
            ),

            const SizedBox(height: 35),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _tabItem("Ingredients", 0, _ingredientsKey),
                _tabItem("Cookware", 1, _cookwareKey),
                _tabItem("Preparation", 2, _preparationKey),
              ],
            ),

            const SizedBox(height: 30),

            Container(
              key: _ingredientsKey,
              child: IngredientSection(
                servings: servings,
                onServingChange: (v) => setState(() => servings = v),
                ingredientData: _ingredientData,
                availableIngredients: availableIngredients
                    .map((e) =>
                        e['item']?.toString().toLowerCase() ?? '')
                    .toList(),
              ),
            ),

            const SizedBox(height: 35),

            Container(
              key: _cookwareKey,
              child: CookwareSection(
                servings: servings,
                cookwareItems: _cookwareItems,
              ),
            ),

            const SizedBox(height: 35),

            Container(
              key: _preparationKey,
              child: PreparationSection(steps: _cookingSteps),
            ),

            const SizedBox(height: 35),

            ReviewSection(
              reviews: _reviewData,
              recipeName: widget.title,
            ),


            const SizedBox(height: 35),

            SimilarRecipesSection(recipes: _similarRecipeData),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _bottomButton(),
      body: CustomScrollView(
        controller: _scrollController,
        physics: ExtremeSpringPhysics(
            springStrength: 1200.0,
            damping: 10.0,
          ),
        slivers: [
          SliverAppBar(
            expandedHeight: 420,
            elevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: widget.image.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: widget.image,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.grey[300]),
                      errorWidget: (context, url, error) => Container(color: Colors.grey[300]),
                    )
                  : Container(color: Colors.grey[300]),
            ),
          ),
          SliverToBoxAdapter(
            child: Material(
              color: Colors.white,
              elevation: 12,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(40),
                topRight: Radius.circular(40),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(26, 0, 26, 60),
                child: _content(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabItem(String text, int index, GlobalKey key) {
    return GestureDetector(
      onTap: () {
        setState(() => selectedTab = index);
        _scrollTo(key);
      },
      child: Column(
        children: [
          Text(text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: selectedTab == index
                    ? const Color(0xFFFF6A45)
                    : Colors.black,
              )),
          if (selectedTab == index)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 100,
              height: 2,
              color: const Color(0xFFFF6A45),
            ),
        ],
      ),
    );
  }

  Widget _bottomButton() {
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.more_horiz, color: Colors.black87, size: 24),
              onPressed: () {
              },
            ),
          ),
          
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6A45).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => IngredientsNeededScreen(
                        servings: servings,
                        ingredients: _ingredientData,
                        steps: _cookingStepsDetailed,
                        recipeName: widget.title,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6A45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Cook Now",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecipeInfoItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _RecipeInfoItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: const BoxDecoration(
            color: Color(0xFFFFECE5),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFFFF6A45), size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}

class _NutritionTile extends StatelessWidget {
  final IconData icon;
  final String label;

  const _NutritionTile({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.4,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFFECE5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 24, color: const Color(0xFFFF6A45)),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
