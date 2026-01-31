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
import 'package:flutter_svg/flutter_svg.dart';

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
    debugPrint('🚀 [RecipeDetailScreen] initState called for: ${widget.title}');
    
    servings = widget.servings;
    _ingredientData = List.from(widget.ingredients); // Use List.from to create a mutable copy
    cookTime = widget.cookTime; 
    
    // Start generating images for initial ingredients parallely - REMOVED to prioritize details fetch
    // _checkAndGenerateImages();
    
    // Check if we have full data passed from previous screen
    if (widget.fullRecipeData != null && widget.fullRecipeData!.isNotEmpty) {
      debugPrint('📦 [RecipeDetailScreen] Using provided fullRecipeData');
      _fullRecipeData = widget.fullRecipeData;
      _extractBackendData();
    } 
    
    // If data is missing or incomplete, trigger a fetch
    // We check if we have either no full data, or if the extracted data is empty/incomplete
    final bool hasDetailedSteps = _cookingSteps.isNotEmpty;
    final bool hasDetailedIngredients = _ingredientData.isNotEmpty && _ingredientData.any((i) => (i['quantity']?.toString().isNotEmpty ?? false));

    if ((_fullRecipeData == null || !hasDetailedSteps || !hasDetailedIngredients) && widget.recipeId != null) {
      debugPrint('🔍 [RecipeDetailScreen] Data incomplete (Steps: ${_cookingSteps.length}, Detailed Ing: $hasDetailedIngredients). Fetching full details for ID: ${widget.recipeId}...');
      _fetchFullRecipeDetails(widget.recipeId!);
    } else {
      debugPrint('✅ [RecipeDetailScreen] Data appears sufficient. No fetch needed.');
      // Only generate images if we aren't fetching
      _checkAndGenerateImages();
    }
    
    // Always fetch similar recipes for the bottom section
    _fetchSimilarRecipes();
  }

  Future<void> _fetchSimilarRecipes() async {
    try {
      debugPrint('🚀 [RecipeDetailScreen] Initiating fetchSimilarRecipes call...');
      final recipes = await RecipeDetailService.fetchSimilarRecipes();
      debugPrint('📥 [RecipeDetailScreen] Recipes received count: ${recipes.length}');
      if (mounted) {
        setState(() {
          _similarRecipeData = recipes;
          debugPrint('✅ [RecipeDetailScreen] State updated with similar recipes');
        });
        
        // Start generating images for recipes that lack them
        _generateSimilarRecipesImages();
      }
    } catch (e) {
      debugPrint('❌ [RecipeDetailScreen] Error fetching similar recipes: $e');
    }
  }

  Future<void> _generateSimilarRecipesImages() async {
    for (var i = 0; i < _similarRecipeData.length; i++) {
      if (!mounted) break;
      
      final recipe = _similarRecipeData[i];
      final title = recipe["recipe_name"] ?? recipe["name"] ?? recipe["title"] ?? "";
      final image = recipe["recipe_image_url"] ?? recipe["image_url"] ?? recipe["image"] ?? "";
      
      if (title.isNotEmpty && image.isEmpty) {
        debugPrint('🖼️ [RecipeDetailScreen] Generating image for similar recipe index $i: $title');
        try {
          final generatedUrl = await RecipeDetailService.generateImage(title);
          debugPrint('🖼️ [RecipeDetailScreen] Generation result for $title: $generatedUrl');
          if (generatedUrl != null && mounted) {
            setState(() {
              _similarRecipeData[i] = {
                ..._similarRecipeData[i],
                'recipe_image_url': generatedUrl,
              };
              debugPrint('✅ [RecipeDetailScreen] Similar recipe at index $i updated with image URL');
            });
          }
        } catch (e) {
          debugPrint('❌ [RecipeDetailScreen] Error generating image for $title: $e');
        }
      } else if (image.isNotEmpty) {
        debugPrint('🖼️ [RecipeDetailScreen] Similar recipe at index $i already has image: $image');
      }
    }
  }

  Future<void> _fetchFullRecipeDetails(String id) async {
    debugPrint('🚀 [RecipeDetailScreen] Fetching full details for ID: $id');
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final data = await RecipeDetailService.fetchRecipeDetails(id);
      
      if (!mounted) return;

      if (data != null && data.isNotEmpty) {
        debugPrint('📥 [RecipeDetailScreen] Received data keys: ${data.keys.join(', ')}');
        debugPrint('📥 [RecipeDetailScreen] Raw Ingredients: ${data['ingredients']}');
        debugPrint('📥 [RecipeDetailScreen] Raw Steps: ${data['cooking_steps']}');
        
        setState(() {
          _fullRecipeData = data;
          isLoading = false;
        });
        _extractBackendData();
        // Now that we have data, we can start generating images
        _checkAndGenerateImages();
      } else {
        debugPrint('⚠️ [RecipeDetailScreen] Fetch returned null or empty data. Keeping existing data.');
        setState(() => isLoading = false);
        
        // If we have absolutely no data (not even title), we might want to show error
        if (_recipeName == null && widget.title == 'Unknown Dish') {
           // Maybe show error or retry?
        }
      }
    } catch (e) {
      debugPrint('❌ [RecipeDetailScreen] Error fetching recipe details: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
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
    if (!mounted) return;
    try {
      final Map<String, dynamic>? rawData = _fullRecipeData;
      if (rawData == null) {
        debugPrint('⚠️ [RecipeDetailScreen] _fullRecipeData is NULL');
        return;
      }
      
      Map<String, dynamic> recipeData = rawData;
      
      // Safety: check if data is nested under 'data' or 'Recipe'
      // Only unwrap if the inner map actually contains recipe data
      if (recipeData.containsKey('data') && recipeData['data'] is Map) {
         final inner = recipeData['data'] as Map;
         if (inner.containsKey('recipe_name') || inner.containsKey('name') || inner.containsKey('title') || inner.containsKey('ingredients')) {
            recipeData = Map<String, dynamic>.from(inner);
            debugPrint('📦 [RecipeDetailScreen] Unwrapped from "data" key');
         }
      } else if (recipeData.containsKey('Recipe') && recipeData['Recipe'] is Map) {
         final inner = recipeData['Recipe'] as Map;
         if (inner.containsKey('recipe_name') || inner.containsKey('name') || inner.containsKey('title')) {
            recipeData = Map<String, dynamic>.from(inner);
            debugPrint('📦 [RecipeDetailScreen] Unwrapped from "Recipe" key');
         }
      }
      
      debugPrint('📦 [RecipeDetailScreen] Full data keys: ${recipeData.keys.join(', ')}');
      debugPrint('📦 [RecipeDetailScreen] Recipe Name Raw: ${recipeData["recipe_name"] ?? recipeData["Recipe Name"] ?? "NULL"}');
      
      setState(() {
        // More aggressive title extraction
        _recipeName = recipeData["recipe_name"]?.toString() ?? 
                     recipeData["Recipe Name"]?.toString() ?? 
                     recipeData["Dish"]?.toString() ?? 
                     recipeData["dish_name"]?.toString() ?? 
                     recipeData["name"]?.toString() ?? 
                     recipeData["title"]?.toString() ?? 
                     (widget.title != 'Unknown Dish' ? widget.title : null) ?? 
                     'Unknown Dish';
        
        _description = recipeData["description"]?.toString() ?? "";
        
        // Image extraction variations
        String? extractedImage;
        final possibleImageFields = [
          "recipe_image_url", "image_url", "imageUrl", "recipeImage", "Dish Image", "image"
        ];
        
        for (final field in possibleImageFields) {
          final val = recipeData[field];
          if (val == null) continue;
          
          if (val is String && val.isNotEmpty) {
            extractedImage = val;
            break;
          } else if (val is Map) {
            extractedImage = val["image_url"]?.toString() ?? val["url"]?.toString() ?? val["image"]?.toString();
            if (extractedImage != null) break;
          }
        }
        
        if (extractedImage != null && extractedImage.isNotEmpty) {
          _recipeImage = extractedImage;
          debugPrint('🖼️ [RecipeDetailScreen] Found image: $_recipeImage');
        }

        // Handle variations in cooking time
        final possibleTimeFields = [
          "cooking_time", "cook_time", "Cooking Time", "time", "total_time", "Preparation Time"
        ];
        for (final field in possibleTimeFields) {
           if (recipeData[field] != null && recipeData[field].toString().isNotEmpty) {
             cookTime = recipeData[field].toString();
             break;
           }
        }
        
        // Extract nutrition
        final rawNutrition = (recipeData["nutrition"] is Map) ? recipeData["nutrition"] as Map : {};
        _nutrition = {
          "calories": rawNutrition["calories"] ?? recipeData["calories"] ?? 250,
          "protein": rawNutrition["protein"] ?? recipeData["protein"] ?? 12,
          "carbs": rawNutrition["carbs"] ?? recipeData["carbs"] ?? 35,
          "fats": rawNutrition["fats"] ?? rawNutrition["fat"] ?? recipeData["fats"] ?? 8,
          "fiber": rawNutrition["fiber"] ?? recipeData["fiber"] ?? 4,
        };
        
        // Extract cooking steps
        final possibleStepFields = [
          "cooking_steps", "preparation_steps", "Recipe Steps", "steps", 
          "directions", "instructions", "Cooking Instruction"
        ];
        
        List<dynamic> rawSteps = [];
        for (final field in possibleStepFields) {
          final stepsVal = recipeData[field];
          debugPrint('📝 [RecipeDetailScreen] Checking step field "$field": ${stepsVal?.runtimeType}');
          
          if (stepsVal != null && (stepsVal is List) && stepsVal.isNotEmpty) {
            rawSteps = stepsVal;
            debugPrint('📝 [RecipeDetailScreen] Found steps in "$field"');
            break;
          }
        }
        
        _cookingStepsDetailed = [];
        for (var step in rawSteps) {
          if (step is Map) {
            _cookingStepsDetailed.add(Map<String, dynamic>.from(step));
          } else if (step is String && step.isNotEmpty) {
            _cookingStepsDetailed.add({"instruction": step});
          }
        }

        _cookingSteps = _cookingStepsDetailed
            .map((e) => (e['instruction'] ?? e['step_description'] ?? e['step'] ?? e['text'] ?? '').toString())
            .where((s) => s.trim().isNotEmpty)
            .toList();
        
        // Fallback: Check if we have a string block of steps that wasn't a list
        if (_cookingSteps.isEmpty) {
           for (final field in possibleStepFields) {
             final val = recipeData[field];
             if (val is String && val.isNotEmpty) {
               debugPrint('📝 [RecipeDetailScreen] Found steps as String in "$field"');
               _cookingSteps = val.split('\n').where((s) => s.trim().isNotEmpty).toList();
               break;
             }
           }
        }
        
        debugPrint('📝 [RecipeDetailScreen] Final extracted steps count: ${_cookingSteps.length}');
        
        // Extract ingredients - very aggressive search
        final possibleIngredientFields = [
          "ingredients", "ingredients_needed", "Ingredients Needed", "items", 
          "components", "recipe_ingredients", "Recipe Ingredients"
        ];
        
        List<dynamic> rawIngredients = [];
        for (final field in possibleIngredientFields) {
          final val = recipeData[field];
          if (val == null) continue;
          
          if (val is List && val.isNotEmpty) {
            rawIngredients = val;
            debugPrint('🍎 [RecipeDetailScreen] Found ingredients as List in "$field"');
            break;
          } else if (val is Map && val.isNotEmpty) {
            // Convert Map to list format
            rawIngredients = val.entries.map((e) => {
              "item": e.key.toString(),
              "qty": e.value.toString(),
            }).toList();
            debugPrint('🍎 [RecipeDetailScreen] Found ingredients as Map in "$field"');
            break;
          }
        }

        if (rawIngredients.isNotEmpty) {
          _ingredientData = rawIngredients.map((ing) {
            if (ing is Map) {
              final name = ing['name'] ?? ing['item'] ?? ing['ingredient'] ?? '';
              
              var qty = (ing['qty'] ?? ing['quantity'] ?? ing['amount'] ?? '').toString();
              var unit = (ing['unit']?.toString() ?? '').trim();
              
              // If unit is missing, check if quantity string contains both number and text
              if (unit.isEmpty && qty.isNotEmpty) {
                 // Try to match "number text" pattern like "2 cups" or "1/2 tbsp"
                 final match = RegExp(r'^([\d\./\s]+)\s*([a-zA-Z%]+.*)$').firstMatch(qty);
                 if (match != null) {
                   // Found a split
                   final parsedQty = match.group(1)?.trim() ?? qty;
                   final parsedUnit = match.group(2)?.trim() ?? '';
                   
                   // Sanity check: if parsedQty is just distinct numbers/fractions
                   if (RegExp(r'^[\d\./\s]+$').hasMatch(parsedQty)) {
                      qty = parsedQty;
                      unit = parsedUnit;
                   }
                 }
              }

              return {
                'item': name,
                'quantity': qty,
                'unit': unit,
                'image_url': ing['image_url'] ?? ing['imageUrl'] ?? ing['image'] ?? '',
              };
            } else {
              // Handle string case like "2 cups Rice"
              final str = ing.toString();
              String qty = '';
              String unit = '';
              String item = str;
              
              // Attempt to parse "2 cups Rice"
              final match = RegExp(r'^([\d\./\s]+)\s+([a-zA-Z]+)\s+(.+)$').firstMatch(str);
              if (match != null) {
                 // Try to guess if group 2 is a unit
                 final possibleUnit = match.group(2)?.trim() ?? '';
                 final possibleItem = match.group(3)?.trim() ?? '';
                 
                 // Simple heuristic for units
                 final commonUnits = ['cup', 'cups', 'tbsp', 'tsp', 'g', 'kg', 'ml', 'l', 'oz', 'lb', 'clove', 'cloves', 'pinch', 'bunch', 'piece', 'pieces', 'slice', 'slices'];
                 if (commonUnits.contains(possibleUnit.toLowerCase()) || possibleUnit.length <= 4) {
                    qty = match.group(1)?.trim() ?? '';
                    unit = possibleUnit;
                    item = possibleItem;
                 }
              }

              return {
                'item': item,
                'quantity': qty,
                'unit': unit,
                'image_url': '',
              };
            }
          }).toList();
        } else if (widget.ingredients.isNotEmpty && _ingredientData.isEmpty) {
          _ingredientData = widget.ingredients;
        }

        // Extract cookware
        _cookwareItems = [];
        if (recipeData['tags'] != null && recipeData['tags'] is Map && (recipeData['tags'] as Map)['cookware'] != null) {
          final List<dynamic> cw = (recipeData['tags'] as Map)['cookware'] as List;
          if (cw.isNotEmpty) {
             _cookwareItems = cw.map((e) => e.toString()).toList();
          }
        } else if (recipeData['Cookware'] != null && recipeData['Cookware'] is List) {
           _cookwareItems = (recipeData['Cookware'] as List).map((e) => e.toString()).toList();
        } else if (recipeData['cookware_needed'] != null && recipeData['cookware_needed'] is List) {
           _cookwareItems = (recipeData['cookware_needed'] as List).map((e) => e.toString()).toList();
        }
        
        if (_cookwareItems.isEmpty) {
           _cookwareItems = ['Gas Stove', 'Pan', 'Blender'];
        }
        
        _reviewData = _generateSampleReviews(_recipeName ?? widget.title);

        // After extracting new ingredients, check if any need image generation
        _checkAndGenerateImages();
        
        debugPrint('✨ [RecipeDetailScreen] Extraction Complete:');
        debugPrint('   - Name: $_recipeName');
        debugPrint('   - Ingredients Count: ${_ingredientData.length}');
        debugPrint('   - Steps Count: ${_cookingSteps.length}');
        debugPrint('   - Image: $_recipeImage');
        
        isLoading = false; 
      });
    } catch (e, stack) {
      debugPrint('❌ [RecipeDetailScreen] Critical error in extraction: $e');
      debugPrint('$stack');
      if (mounted) {
        setState(() => isLoading = false);
      }
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
        "imageUrl": "https://i.pravatar.cc/150?img=5",
        "isAI": false,
      },
      {
        "name": "Mike Chen",
        "rating": 4,
        "comment": "Great recipe for $recipeName! I added a little extra spice and it turned out amazing. My family loved it.",
        "timeAgo": "1 week ago",
        "imageUrl": "https://i.pravatar.cc/150?img=11",
        "isAI": false,
      },
      {
        "name": "Emily Davis",
        "rating": 5,
        "comment": "This $recipeName recipe is now my go-to! Perfect for dinner parties and always gets compliments. Thank you for sharing!",
        "timeAgo": "2 weeks ago",
        "imageUrl": "https://i.pravatar.cc/150?img=9",
        "isAI": false,
      }
    ];
  }

  void _checkAndGenerateImages() {
    // Generate images sequentially (one by one) instead of all at once
    _generateImagesSequentially();
  }

  void _addReview(String comment) {
    setState(() {
      _reviewData.insert(0, {
        "name": "You",
        "rating": 5, // Default rating for now
        "comment": comment,
        "timeAgo": "Just now",
        "imageUrl": "https://i.pravatar.cc/150?img=12", // Default user image
        "isAI": false,
      });
    });
  }

  Future<void> _generateImagesSequentially() async {
    for (var item in _ingredientData) {
      if (!mounted) break; // STOP generation if user leaves screen
      
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
    if (_pendingGenerations.contains(name) || !mounted) return;

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
    if (!mounted) return;
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



  Widget _sectionDivider() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Divider(thickness: 1, color: Colors.grey.shade200),
        const SizedBox(height: 20),
      ],
    );
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
            const SizedBox(height: 5),
            Text(_recipeName ?? widget.title,
                style:
                    const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(height: 22),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  widget.cuisine,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '${_nutrition["calories"]?.toString() ?? "--"} kcal',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  (cookTime.isEmpty ? "N/A" : cookTime).replaceAll("minutes", "m").replaceAll("mins", "m").replaceAll("min", "m"),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.people_outline, size: 20, color: Color(0xFFFF6A45)),
                    const SizedBox(width: 4),
                    Text(
                      servings.toString(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 22),

            LayoutBuilder(
              builder: (context, constraints) {
                // Combine DefaultTextStyle with our custom style to ensure accurate measurement
                final defaultTextStyle = DefaultTextStyle.of(context);
                final style = defaultTextStyle.style.copyWith(color: Colors.black);
                
                final span = TextSpan(text: _description, style: style);
                final tp = TextPainter(
                  text: span,
                  textAlign: TextAlign.left,
                  textDirection: TextDirection.ltr,
                );
                tp.layout(maxWidth: constraints.maxWidth);
                
                // Check actual number of lines
                final numLines = tp.computeLineMetrics().length;

                if (numLines > 2) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _description,
                        style: style,
                        maxLines: isExpanded ? null : 2,
                        overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () => setState(() => isExpanded = !isExpanded),
                        child: Text(
                          isExpanded ? "Read less.." : "Read more..",
                          style: style.copyWith(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  return Text(_description, style: style);
                }
              },
            ),

            const SizedBox(height: 30),

            const Text("Nutrition per serving",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black)),

            const SizedBox(height: 20),

            Wrap(
              spacing: 20,
              runSpacing: 18,
              children: [
                _NutritionTile(
                    svgAsset: "assets/images/nutrition/carbs.svg",
                    label: '${_nutrition["carbs"]?.toString() ?? "--"}g',
                    title: "Carbs"),
                _NutritionTile(
                    svgAsset: "assets/images/nutrition/protein.svg",
                    label: '${_nutrition["protein"]?.toString() ?? "--"}g',
                    title: "Protein"),
                _NutritionTile(
                    svgAsset: "assets/images/nutrition/kcal.svg",
                    label: '${_nutrition["calories"]?.toString() ?? "--"}',
                    title: "Kcal"),
                _NutritionTile(
                    svgAsset: "assets/images/nutrition/fat.svg",
                    label: '${_nutrition["fats"]?.toString() ?? "--"}g',
                    title: "Fat"),
              ],
            ),

            _sectionDivider(),
            
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

            _sectionDivider(),

            Container(
              key: _cookwareKey,
              child: CookwareSection(
                servings: servings,
                cookwareItems: _cookwareItems,
              ),
            ),

            _sectionDivider(),

            Container(
              key: _preparationKey,
              child: PreparationSection(steps: _cookingSteps),
            ),

            _sectionDivider(),

            if (_reviewData != null)
              ReviewSection(
                reviews: _reviewData!,
                recipeName: _recipeName ?? widget.title,
                onAddReview: _addReview,
              ),


            _sectionDivider(),

            SimilarRecipesSection(
              recipes: _similarRecipeData,
              onRecipeTap: (recipe) {
                // Navigate to new recipe details screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RecipeDetailScreen(
                      recipeId: recipe['_id'] ?? recipe['id'],
                      image: recipe['recipe_image_url'] ?? recipe['image_url'] ?? recipe['image'] ?? '',
                      title: recipe['recipe_name'] ?? recipe['name'] ?? recipe['title'] ?? 'Unknown Dish',
                      ingredients: const [], // Will be fetched by ID
                      cuisine: recipe['cuisine'] ?? 'Indian',
                      cookTime: (recipe['cooking_time'] ?? recipe['cook_time'] ?? '30-40 min').toString(),
                      servings: 4,
                      fullRecipeData: recipe, // Pass what we have
                    ),
                  ),
                );
              },
            ),
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
    
    // Check if we really have no data to show
    if (_ingredientData.isEmpty && _cookingSteps.isEmpty && widget.recipeId != null) {
       return Scaffold(
         backgroundColor: Colors.white,
         appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: const BackButton(color: Colors.black)),
         body: Center(
           child: Padding(
             padding: const EdgeInsets.all(24.0),
             child: Column(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 const Icon(Icons.error_outline, size: 48, color: Color(0xFFFF6A45)),
                 const SizedBox(height: 16),
                 const Text(
                   'Could not load recipe details',
                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                 ),
                 const SizedBox(height: 8),
                 const Text(
                   'The server took too long to respond.',
                   textAlign: TextAlign.center,
                   style: TextStyle(color: Colors.grey),
                 ),
                 const SizedBox(height: 24),
                 ElevatedButton(
                   onPressed: () => _fetchFullRecipeDetails(widget.recipeId!),
                   style: ElevatedButton.styleFrom(
                     backgroundColor: const Color(0xFFFF6A45),
                     foregroundColor: Colors.white,
                     padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                   ),
                   child: const Text('Retry'),
                 ),
               ],
             ),
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
            leading: Padding(
              padding: const EdgeInsets.only(left: 20, top: 8, bottom: 8), // Adjust padding for positioning
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: SvgPicture.asset(
                  "assets/images/icons/back_arrow.svg",
                  width: 48,
                  height: 48,
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 20, top: 8, bottom: 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      isFavorite = !isFavorite;
                    });
                  },
                  child: SvgPicture.asset(
                    isFavorite 
                      ? "assets/images/icons/heart_filled.svg" 
                      : "assets/images/icons/heart.svg",
                    width: 48,
                    height: 48,
                  ),
                ),
              ),
            ],
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
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(30),
              child: Container(
                height: 30,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
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
                        initialGeneratedImages: _locallyGeneratedImages,
                        cookware: _cookwareItems,
                        description: _description,
                        recipeImage: (_recipeImage?.isNotEmpty ?? false) ? _recipeImage! : widget.image,
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



class _NutritionTile extends StatelessWidget {
  final String svgAsset;
  final String label;
  final String title;

  const _NutritionTile({required this.svgAsset, required this.label, required this.title});

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
              color: Colors.transparent, 
              borderRadius: BorderRadius.circular(16),
            ),
            child: SvgPicture.asset(svgAsset, width: 48, height: 48),
          ),
          const SizedBox(width: 12),
          Text(
            "$label $title",
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
