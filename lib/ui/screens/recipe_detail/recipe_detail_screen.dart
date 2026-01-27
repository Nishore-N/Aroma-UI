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
  final String? recipeId;
  final Map<String, dynamic>? fullRecipeData; // Optional, can be fetched if null

  const RecipeDetailScreen({
    super.key,
    required this.image,
    required this.title,
    required this.ingredients,
    required this.cuisine,
    required this.cookTime,
    required this.servings,
    this.recipeId,
    this.fullRecipeData,
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  bool isExpanded = false;
  bool isFavorite = false;
  bool isSaved = false;
  bool isLoading = false;
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
  String? _recipeName;
  String? _recipeImage;
  Map<String, dynamic>? _fullRecipeData;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _ingredientsKey = GlobalKey();
  final GlobalKey _cookwareKey = GlobalKey();
  final GlobalKey _preparationKey = GlobalKey();

  int selectedTab = 0;

  final Set<String> _pendingGenerations = {};
  final Map<String, String> _locallyGeneratedImages = {};

  @override
  void initState() {
    super.initState();
    servings = widget.servings;
    _ingredientData = widget.ingredients;
    cookTime = widget.cookTime; 
    
    debugPrint('🔍 RecipeDetailScreen initState called');
    
    // Start generating images for initial ingredients parallely
    _checkAndGenerateImages();
    
    if (widget.fullRecipeData != null) {
      debugPrint('📦 [RecipeDetailScreen] Using provided fullRecipeData');
      _fullRecipeData = widget.fullRecipeData;
      _extractBackendData();
    } else if (widget.recipeId != null) {
      debugPrint('🔗 [RecipeDetailScreen] recipeId provided: ${widget.recipeId}, fetching details...');
      _fetchFullRecipeDetails(widget.recipeId!);
    } else {
      debugPrint('❌ [RecipeDetailScreen] Error: Both fullRecipeData and recipeId are NULL');
      setState(() {
        isLoading = false;
        // You might want to show an error UI here
      });
    }
  }

  Future<void> _fetchFullRecipeDetails(String id) async {
    debugPrint('🚀 [RecipeDetailScreen] Fetching full details for ID: $id');
    setState(() => isLoading = true);
    try {
      final data = await RecipeDetailService.fetchRecipeDetails(id);
      debugPrint('📥 [RecipeDetailScreen] Received data keys: ${data.keys.join(', ')}');
      setState(() {
        _fullRecipeData = data;
        isLoading = false;
      });
      _extractBackendData();
    } catch (e) {
      debugPrint('❌ [RecipeDetailScreen] Error fetching recipe details: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _generateFallbackImage() async {
    try {
      final generatedUrl = await RecipeDetailService.generateImage(_recipeName ?? widget.title);
      if (generatedUrl != null && mounted) {
        setState(() {
          _recipeImage = generatedUrl;
        });
        debugPrint('✅ [RecipeDetailScreen] Fallback image generated: $_recipeImage');
      }
    } catch (e) {
      debugPrint('❌ [RecipeDetailScreen] Error generating fallback image: $e');
    }
  }

  void _extractBackendData() {
    debugPrint('🧪 [RecipeDetailScreen] _extractBackendData called');
    try {
      final recipeData = _fullRecipeData;
      if (recipeData == null) {
        debugPrint('⚠️ [RecipeDetailScreen] _fullRecipeData is NULL');
        return;
      }
      
      debugPrint('📦 [RecipeDetailScreen] Extracting from data with keys: ${recipeData.keys.join(', ')}');
      
      setState(() {
        _recipeName = recipeData["recipe_name"] ?? recipeData["Dish"] ?? widget.title;
        _description = recipeData["description"]?.toString() ?? "";
        
        // Image extraction variations
        String? extractedImage;
        if (recipeData["recipe_image_url"] != null && recipeData["recipe_image_url"].toString().isNotEmpty) {
          extractedImage = recipeData["recipe_image_url"].toString();
        } else if (recipeData["image_url"] != null && recipeData["image_url"].toString().isNotEmpty) {
          extractedImage = recipeData["image_url"].toString();
        } else if (recipeData["imageUrl"] != null && recipeData["imageUrl"].toString().isNotEmpty) {
          extractedImage = recipeData["imageUrl"].toString();
        } else if (recipeData["image"] != null) {
          if (recipeData["image"] is String && recipeData["image"].toString().isNotEmpty) {
            extractedImage = recipeData["image"].toString();
          } else if (recipeData["image"] is Map) {
            extractedImage = recipeData["image"]["image_url"]?.toString() ?? 
                           recipeData["image"]["url"]?.toString();
          }
        }

        // Prioritize extracted image, fallback to widget.image (from list screen)
        _recipeImage = (extractedImage != null && extractedImage.isNotEmpty && extractedImage != "null")
            ? extractedImage
            : (widget.image.isNotEmpty && widget.image != "null") ? widget.image : null;

        if (_recipeImage != null && _recipeImage!.startsWith('http://') && _recipeImage!.contains('s3')) {
          _recipeImage = _recipeImage!.replaceFirst('http://', 'https://');
        }

        debugPrint('🖼️ [RecipeDetailScreen] Final image URL: $_recipeImage');
        
        // Fallback: If still no image, try to generate one based on recipe name
        if (_recipeImage == null || _recipeImage!.isEmpty) {
          debugPrint('🪄 [RecipeDetailScreen] No image found, attempting to generate fallback...');
          debugPrint('🔍 [RecipeDetailScreen] Data keys: ${recipeData.keys.join(', ')}');
          _generateFallbackImage();
        }
        
        // Extract cooking time
        final possibleTimeFields = [
          "cooking_time", "total_time", "time", "Cooking Time", "totalTime"
        ];
        
        for (final field in possibleTimeFields) {
          if (recipeData[field] != null && recipeData[field].toString().isNotEmpty) {
            cookTime = recipeData[field].toString();
            break;
          }
        }
        if (cookTime.isEmpty) cookTime = "30 min";
        debugPrint('⏰ [RecipeDetailScreen] Extracted cookTime: $cookTime');
        
        // Extract nutrition
        final rawNutrition = recipeData["nutrition"] ?? {};
        _nutrition = {
          "calories": rawNutrition["calories"] ?? recipeData["calories"] ?? 250,
          "protein": rawNutrition["protein"] ?? recipeData["protein"] ?? 12,
          "carbs": rawNutrition["carbs"] ?? recipeData["carbs"] ?? 35,
          "fats": rawNutrition["fats"] ?? rawNutrition["fat"] ?? recipeData["fats"] ?? 8,
          "fiber": rawNutrition["fiber"] ?? recipeData["fiber"] ?? 4,
        };
        debugPrint('🥗 [RecipeDetailScreen] Extracted nutrition: $_nutrition');
        
        // Extract cooking steps
        final possibleStepFields = [
          "cooking_steps", "preparation_steps", "Recipe Steps", "steps", "Cooking Steps", "directions"
        ];
        
        List<dynamic> rawSteps = [];
        for (final field in possibleStepFields) {
          if (recipeData[field] != null && (recipeData[field] is List) && (recipeData[field] as List).isNotEmpty) {
            rawSteps = recipeData[field];
            debugPrint('📝 [RecipeDetailScreen] Found steps in field: $field');
            break;
          }
        }
        
        _cookingStepsDetailed = [];
        for (var step in rawSteps) {
          if (step is Map) {
            _cookingStepsDetailed.add(Map<String, dynamic>.from(step));
          } else if (step is String) {
            _cookingStepsDetailed.add({"instruction": step});
          }
        }

        _cookingSteps = _cookingStepsDetailed
            .map((e) => (e['instruction'] ?? e['step'] ?? e['text'] ?? '').toString())
            .where((s) => s.trim().isNotEmpty)
            .toList();
        debugPrint('📝 [RecipeDetailScreen] Extracted ${_cookingSteps.length} cooking steps');
        
        // Extract ingredients
        final possibleIngredientFields = [
          "ingredients", "ingredients_needed", "Ingredients Needed", "items", "components"
        ];
        
        List<dynamic> rawIngredients = [];
        for (final field in possibleIngredientFields) {
          if (recipeData[field] != null && (recipeData[field] is List) && (recipeData[field] as List).isNotEmpty) {
            rawIngredients = recipeData[field];
            debugPrint('🍎 [RecipeDetailScreen] Found ingredients in field: $field');
            break;
          }
        }

        if (rawIngredients.isNotEmpty) {
          _ingredientData = rawIngredients.map((ing) {
            if (ing is Map) {
              final name = ing['name'] ?? ing['item'] ?? ing['ingredient'] ?? '';
              final qty = ing['qty'] ?? ing['quantity'] ?? ing['amount'] ?? '';
              final unit = ing['unit'] ?? '';
              
              return {
                'item': name,
                'quantity': qty,
                'unit': unit,
                'image_url': ing['image_url'] ?? ing['imageUrl'] ?? ing['image'] ?? '',
              };
            } else {
              return {
                'item': ing.toString(),
                'quantity': '',
                'unit': '',
                'image_url': '',
              };
            }
          }).toList();
        }
        debugPrint('🍎 [RecipeDetailScreen] Extracted ${_ingredientData.length} ingredients');
        
        _cookwareItems = ['Gas Stove', 'Pan', 'Blender']; // Default fallbacks
        if (recipeData['tags'] != null && recipeData['tags']['cookware'] != null) {
          final List<dynamic> cw = recipeData['tags']['cookware'];
          if (cw.isNotEmpty) {
            _cookwareItems = cw.map((e) => e.toString()).toList();
          }
        }
        
        _reviewData = _generateSampleReviews(widget.title);

        // After extracting new ingredients, check if any need image generation
        _checkAndGenerateImages();
      });
      
    } catch (e) {
      debugPrint('❌ [RecipeDetailScreen] Error extracting backend data: $e');
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

  void _checkAndGenerateImages() {
    // Generate images sequentially (one by one) instead of all at once
    _generateImagesSequentially();
  }

  Future<void> _generateImagesSequentially() async {
    for (var item in _ingredientData) {
      final name = item['item']?.toString() ?? '';
      final imageUrl = item['image_url']?.toString() ?? 
                     item['imageUrl']?.toString() ?? 
                     item['image']?.toString() ?? '';

      if (name.isNotEmpty && imageUrl.isEmpty && !_locallyGeneratedImages.containsKey(name) && !_pendingGenerations.contains(name)) {
        // Wait for each image to complete before starting the next one
        await _generateImageForIngredient(name);
        debugPrint('✅ [RecipeDetailScreen] Completed image generation for: $name');
      }
    }
    debugPrint('🎉 [RecipeDetailScreen] All ingredient images generated sequentially');
  }

  Future<void> _generateImageForIngredient(String name) async {
    if (_pendingGenerations.contains(name)) return;

    setState(() {
      _pendingGenerations.add(name);
    });

    try {
      final generatedUrl = await RecipeDetailService.generateImage(name, isRecipe: false);
      if (mounted) {
        if (generatedUrl != null) {
          _onIngredientImageGenerated(name, generatedUrl);
        }
        setState(() {
          _pendingGenerations.remove(name);
        });
      }
    } catch (e) {
      debugPrint('❌ [RecipeDetailScreen] Error generating image for $name: $e');
      if (mounted) {
        setState(() {
          _pendingGenerations.remove(name);
        });
      }
    }
  }

  void _onIngredientImageGenerated(String name, String imageUrl) {
    debugPrint('🖼️ [RecipeDetailScreen] Image generated for $name: $imageUrl');
    setState(() {
      _locallyGeneratedImages[name] = imageUrl;

      // Update _ingredientData
      for (var i = 0; i < _ingredientData.length; i++) {
        if ((_ingredientData[i]['item']?.toString() ?? '') == name) {
          _ingredientData[i] = {
            ..._ingredientData[i],
            'image_url': imageUrl,
          };
          break;
        }
      }

      // Also update _cookingStepsDetailed if they contain this ingredient
      for (var i = 0; i < _cookingStepsDetailed.length; i++) {
        if (_cookingStepsDetailed[i]['ingredients_used'] != null) {
          final ingredients = _cookingStepsDetailed[i]['ingredients_used'] as List;
          bool updated = false;
          for (var j = 0; j < ingredients.length; j++) {
            if (ingredients[j] is Map) {
              final ingName = ingredients[j]['item']?.toString() ?? 
                            ingredients[j]['name'] ?? 
                            ingredients[j]['ingredient'] ?? '';
              if (ingName == name) {
                ingredients[j] = {
                  ...ingredients[j] as Map<String, dynamic>,
                  'image_url': imageUrl,
                };
                updated = true;
              }
            }
          }
          if (updated) {
            _cookingStepsDetailed[i]['ingredients_used'] = ingredients;
          }
        }
      }
    });
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
            Text(_recipeName ?? widget.title,
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
                onImageGenerated: _onIngredientImageGenerated,
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
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(Color(0xFFFF6A45)),
          ),
        ),
      );
    }
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
              background: Builder(
                builder: (context) {
                  final displayUrl = (_recipeImage?.isNotEmpty ?? false) ? _recipeImage! : widget.image;
                  final isValidUrl = displayUrl.isNotEmpty && (displayUrl.startsWith('http://') || displayUrl.startsWith('https://'));
                  
                  return isValidUrl
                    ? CachedNetworkImage(
                        imageUrl: displayUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: Colors.grey[300]),
                        errorWidget: (context, url, error) => Container(color: Colors.grey[300]),
                      )
                    : Container(color: Colors.grey[300]);
                }
              ),
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
