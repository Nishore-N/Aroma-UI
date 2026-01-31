import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../recipe_detail/recipe_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/services/home_recipe_service.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../data/services/preference_api_service.dart';
import '../../../data/services/recipe_detail_service.dart';
import 'package:provider/provider.dart';
import '../../../state/pantry_state.dart';
import '../../widgets/recipe_card.dart';

class RecipeListScreen extends StatefulWidget {
  final List<Map<String, dynamic>> ingredients;
  final Map<String, dynamic> preferences;
  final List<dynamic>? initialRecipes;

  const RecipeListScreen({
    super.key,
    required this.ingredients,
    required this.preferences,
    this.initialRecipes,
  });

  @override
  State<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen> {
  final List<_RecipeData> _allRecipes = [];
  final List<String> _excludedIds = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasError = false;

  final Set<int> _likedIndices = {};

  final HomeRecipeService _homeRecipeService = HomeRecipeService();

  @override
  void initState() {
    super.initState();
    if (widget.initialRecipes != null && widget.initialRecipes!.isNotEmpty) {
      _processRecipes(widget.initialRecipes!, append: false);
    } else {
      _fetchRecipes();
    }
  }

  // Queue for sequential image generation
  final List<Future<void> Function()> _taskQueue = [];
  bool _isProcessingQueue = false;

  void _addToQueue(String key, Future<void> Function() task) {
    _taskQueue.add(task);
    _processQueue();
  }

  Future<void> _processQueue() async {
    if (_isProcessingQueue) return;
    _isProcessingQueue = true;

    while (_taskQueue.isNotEmpty && mounted) {
      final task = _taskQueue.removeAt(0);
      try {
        await task();
        // Small delay to be nice to the network/server
        await Future.delayed(const Duration(milliseconds: 200));
      } catch (e) {
        debugPrint('❌ [RecipeListScreen] Error processing queue task: $e');
      }
    }

    _isProcessingQueue = false;
  }

  Future<void> _generateFallbackImageForRecipe(String title, int index) async {
    try {
      if (!mounted) return;
      debugPrint('🖼️ [RecipeListScreen] Starting generation for: $title');
      final imageUrl = await RecipeDetailService.generateImage(title);
      if (imageUrl != null && mounted) {
        setState(() {
          // If the list has changed, we need to be careful with indexing
          if (index < _allRecipes.length && _allRecipes[index].title == title) {
            _allRecipes[index].image = imageUrl;
          }
        });
        debugPrint('✅ [RecipeListScreen] Fallback image generated for: $title');
      }
    } catch (e) {
      debugPrint('❌ [RecipeListScreen] Error generating image for $title: $e');
    }
  }

  void _processRecipes(List<dynamic> recipeList, {bool append = false}) {
    debugPrint('🔄 [RecipeListScreen] Processing ${recipeList.length} recipes (append: $append)');
    setState(() {
      if (!append) {
        _allRecipes.clear();
        _excludedIds.clear();
      }
      
      for (var item in recipeList) {
        if (item is! Map) {
          debugPrint('⚠️ [RecipeListScreen] item is not a Map: $item');
          continue;
        }
        
        final Map<String, dynamic> itemMap = Map<String, dynamic>.from(item);
        
        // Robust ID extraction
        final String? id = itemMap["_id"]?.toString() ?? 
                           itemMap["id"]?.toString() ?? 
                           itemMap["recipeId"]?.toString() ??
                           itemMap["recipe_id"]?.toString();
                           
        if (id != null) {
          if (!_excludedIds.contains(id)) {
            _excludedIds.add(id);
          }
        } else {
          debugPrint('⚠️ [RecipeListScreen] Recipe has no ID field! Keys: ${itemMap.keys.join(', ')}');
        }

        final recipeTitle = itemMap["recipe_name"] ?? itemMap["Dish"] ?? "Unknown Dish";
        
        // Robust Image extraction based on user snippet
        String? recipeImageUrl;
        
        // Log all keys to see what's available
        debugPrint('🔍 [RecipeListScreen] Keys for $recipeTitle: ${itemMap.keys.join(', ')}');
        
        if (itemMap["recipe_image_url"] != null && itemMap["recipe_image_url"].toString().isNotEmpty) {
          recipeImageUrl = itemMap["recipe_image_url"].toString();
        } else if (itemMap["image_url"] != null && itemMap["image_url"].toString().isNotEmpty) {
          recipeImageUrl = itemMap["image_url"].toString();
        } else if (itemMap["imageUrl"] != null && itemMap["imageUrl"].toString().isNotEmpty) {
          recipeImageUrl = itemMap["imageUrl"].toString();
        } else if (itemMap["image"] != null) {
          if (itemMap["image"] is String && itemMap["image"].toString().isNotEmpty) {
            recipeImageUrl = itemMap["image"].toString();
          } else if (itemMap["image"] is Map) {
            recipeImageUrl = itemMap["image"]["image_url"]?.toString() ?? 
                           itemMap["image"]["url"]?.toString() ??
                           itemMap["image"]["imageUrl"]?.toString();
          }
        } 
        
        if ((recipeImageUrl == null || recipeImageUrl.isEmpty) && itemMap["Image"] != null && itemMap["Image"] is Map) {
          recipeImageUrl = itemMap["Image"]["image_url"]?.toString() ?? 
                         itemMap["Image"]["url"]?.toString() ??
                         itemMap["Image"]["imageUrl"]?.toString();
        }
        
        // Final cleaning
        if (recipeImageUrl != null) {
          if (recipeImageUrl == "null" || recipeImageUrl.isEmpty) {
            recipeImageUrl = null;
          } else if (recipeImageUrl.startsWith('http://') && recipeImageUrl.contains('s3')) {
            recipeImageUrl = recipeImageUrl.replaceFirst('http://', 'https://');
          }
        }

        if (recipeImageUrl == null) {
          debugPrint('🖼️ [RecipeListScreen] ❌ No image found for: $recipeTitle. Queueing local generation.');
          // Use a capture of current index and title
          final currentIndex = _allRecipes.length;
          _addToQueue(
            recipeTitle, 
            () => _generateFallbackImageForRecipe(recipeTitle, currentIndex)
          );
        } else {
          debugPrint('🖼️ [RecipeListScreen] ✅ Image found for: $recipeTitle -> $recipeImageUrl');
        }
        
        final recipe = _RecipeData(
          image: recipeImageUrl ?? "",
          title: recipeTitle,
          cuisine: itemMap['cuisine'] ?? itemMap['Cuisine'] ?? widget.preferences['cuisine'] ?? "Indian",
          time: "${widget.preferences['time'] ?? 30} min",
          fullRecipeData: itemMap,
        );

        _allRecipes.add(recipe);
      }

      _isLoading = false;
      _isLoadingMore = false;
      _hasError = false;

      // Record usage of ingredients
      if (mounted) {
        final pantryState = Provider.of<PantryState>(context, listen: false);
        final ingredientNames = widget.ingredients.map((e) => e['name']?.toString() ?? '').toList();
        pantryState.recordUsage(ingredientNames);
      }
    });
  }

  Future<void> _fetchRecipes({bool isLoadMore = false}) async {
    setState(() {
      if (isLoadMore) {
        _isLoadingMore = true;
      } else {
        _isLoading = true;
      }
      _hasError = false;
    });

    try {
      final recipesData = await PreferenceApiService.generateRecipes(
        widget.ingredients, 
        widget.preferences,
        excludeRecipeIds: _excludedIds,
      );
      
      debugPrint('📥 [RecipeListScreen] API Response keys: ${recipesData.keys.join(', ')}');
      if (recipesData['data'] != null && recipesData['data'] is Map) {
        debugPrint('🍱 [RecipeListScreen] data keys: ${recipesData['data'].keys.join(', ')}');
      }

      final recipeList = List<dynamic>.from(
        recipesData['data']?['recipes'] ?? 
        recipesData['data']?['Recipes'] ?? 
        recipesData['recipes'] ?? 
        []
      );
      
      debugPrint('📝 [RecipeListScreen] Found ${recipeList.length} recipes in response');
      
      if (recipeList.isNotEmpty) {
        _processRecipes(recipeList, append: true);
      } else {
         setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching recipes: $e");
      setState(() {
        _hasError = true;
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _loadMore() {
    if (_isLoadingMore) return;
    _fetchRecipes(isLoadMore: true);
  }

  void _toggleLike(int index) {
    setState(() {
      _likedIndices.contains(index)
          ? _likedIndices.remove(index)
          : _likedIndices.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 30, 18, 140),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
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
            ),

            const SizedBox(height: 16),
            const Text(
              "Recipes for you",
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 26),
            ),
            const SizedBox(height: 28),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_hasError && _allRecipes.isEmpty)
              const Center(child: Text("Error loading recipes"))
            else
              Column(
                children: [
                   for (int i = 0; i < _allRecipes.length; i++) ...[
                    _RecipeCard(
                      key: ValueKey('${_allRecipes[i].title}_${_allRecipes[i].image}'),
                      data: _allRecipes[i],
                      isLiked: _likedIndices.contains(i),
                      onToggleLike: () => _toggleLike(i),
                      ingredients: widget.ingredients,
                      preferences: widget.preferences,
                    ),
                    const SizedBox(height: 30),
                  ],

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _loadMore,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6A45),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: _isLoadingMore 
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Load more recipes',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        'Show All Categories',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 26),

                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      color: const Color(0xFFFFF1EA),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.support_agent, size: 48),
                        SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            "Not what you're looking for?\nHelp us improve →",
                            style: TextStyle(
                              fontSize:16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _RecipeData {
  String image;
  final String title;
  final String cuisine;
  final String time;
  final Map<String, dynamic> fullRecipeData; 

  _RecipeData({
    required this.image,
    required this.title,
    required this.cuisine,
    required this.time,
    required this.fullRecipeData,
  });
}

class _RecipeCard extends StatelessWidget {
  final _RecipeData data;
  final bool isLiked;
  final VoidCallback onToggleLike;
  final List<Map<String, dynamic>> ingredients; 
  final Map<String, dynamic> preferences;

  const _RecipeCard({
    super.key,
    required this.data,
    required this.isLiked,
    required this.onToggleLike,
    required this.ingredients, 
    required this.preferences,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        height: 470,
        child: Stack(
          children: [
            Positioned.fill(
              child: (data.image.isNotEmpty && (data.image.startsWith('http://') || data.image.startsWith('https://')))
                  ? CachedNetworkImage(
                      imageUrl: data.image,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => _loadingPlaceholder(),
                      errorWidget: (context, url, error) => _loadingPlaceholder(),
                    )
                  : _loadingPlaceholder(),
            ),

            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black26,
                      Colors.black87,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _infoIcon(
                        const GenAiIcon(size: 16, color: Colors.white),
                        "Gen-AI"
                      ),
                      const SizedBox(width: 14),
                      _infoIcon(
                        const RestaurantTypeIcon(size: 16, color: Colors.white),
                        data.cuisine
                      ),
                      const SizedBox(width: 14),
                      _infoIcon(
                        const TimerIcon(size: 16, color: Colors.white),
                        data.time
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            final fullData = data.fullRecipeData;
                            final recipeId = fullData["_id"]?.toString() ?? 
                                             fullData["id"]?.toString() ?? 
                                             fullData["recipeId"]?.toString() ??
                                             fullData["recipe_id"]?.toString();
                            
                            debugPrint('👉 [RecipeListScreen] "Cook Now" clicked for: ${data.title}');
                            debugPrint('📄 [RecipeListScreen] fullRecipeData keys: ${fullData.keys.join(', ')}');
                            debugPrint('🆔 [RecipeListScreen] Extracted ID: $recipeId');
                            
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RecipeDetailScreen(
                                  image: data.image,
                                  title: data.title,
                                  ingredients: ingredients, 
                                  cuisine: preferences["cuisine"]?.toString() ?? "Indian",
                                  cookTime: preferences["time"]?.toString() ?? "30m",
                                  servings: int.tryParse(preferences["servings"]?.toString() ?? "4") ?? 4,
                                  recipeId: recipeId,
                                  // fullRecipeData: data.fullRecipeData, // Force fetch full details
                                ),
                              ),
                            );
                          },
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Text(
                                'Cook now',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: onToggleLike,
                        child: Container(
                          height: 52,
                          width: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white70),
                            color: Colors.white.withOpacity(0.22),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: const Color(0xFFFF8FA7),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Save',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

Widget _infoIcon(Widget icon, String text) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      icon,
      const SizedBox(width: 4),
      Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    ],
  );
}

Widget _loadingPlaceholder() {
  return Container(
    color: const Color(0xFFF4F4F4),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation(Color(0xFFFF6A45)),
          ),
        ),
        SizedBox(height: 14),
        Text(
          'Preparing your recipe…',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
      ],
    ),
  );
}
