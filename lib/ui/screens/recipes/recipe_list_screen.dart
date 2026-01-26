import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../recipe_detail/recipe_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/services/home_recipe_service.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../widgets/recipe_card.dart';

class RecipeListScreen extends StatefulWidget {
  final List<Map<String, dynamic>> ingredients;
  final Map<String, dynamic> preferences;

  const RecipeListScreen({
    super.key,
    required this.ingredients,
    required this.preferences,
  });

  @override
  State<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen> {
  final List<_RecipeData> _allRecipes = [];
  bool _isLoading = true;
  bool _hasError = false;

  int _visibleCount = 3;
  final Set<int> _likedIndices = {};

  final HomeRecipeService _homeRecipeService = HomeRecipeService();

  @override
  void initState() {
    super.initState();
    _fetchRecipes();
  }

  // Background image generation removed

  Future<void> _fetchRecipes() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _allRecipes.clear();
    });

    try {
      final Map<String, dynamic> requestData = Map.from(widget.preferences);
      requestData['Ingredients_Available'] = widget.ingredients.map((e) => e['item'] ?? e['name']).toList();

      final recipeList = await _homeRecipeService.generateWeeklyRecipes(requestData);
      
      if (recipeList.isNotEmpty) {
        print('📋 Backend returned ${recipeList.length} recipes');
        
        for (var item in recipeList) {
          if (item is! Map<String, dynamic>) continue;
          
          final recipeTitle = item["recipe_name"] ?? item["Dish"] ?? "Unknown Dish";
          
          String? recipeImageUrl;
          if (item["recipe_image_url"] != null) {
            recipeImageUrl = item["recipe_image_url"];
          } else if (item["image"] != null) {
            if (item["image"] is String) {
              recipeImageUrl = item["image"];
            } else if (item["image"] is Map) {
              recipeImageUrl = item["image"]["image_url"]?.toString() ?? 
                             item["image"]["url"]?.toString();
            }
          } else if (item["Image"] != null && item["Image"] is Map) {
            recipeImageUrl = item["Image"]["image_url"]?.toString() ?? 
                           item["Image"]["url"]?.toString();
          }
          
          final recipe = _RecipeData(
            image: recipeImageUrl ?? "",
            title: recipeTitle,
            cuisine: item['cuisine'] ?? item['Cuisine'] ?? widget.preferences['cuisine'] ?? "Indian",
            time: "${widget.preferences['time'] ?? 30} min",
            fullRecipeData: item,
          );

          _allRecipes.add(recipe);
        }

        // _generateRecipeImagesInBackground(_allRecipes);

        setState(() {
          _visibleCount = _allRecipes.length >= 3 ? 3 : _allRecipes.length;
          _isLoading = false;
        });
      } else {
         setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching recipes: $e");
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  void _loadMore() {
    setState(() {
      _visibleCount =
          (_visibleCount + 2).clamp(0, _allRecipes.length);
    });
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
            else if (_hasError)
              const Center(child: Text("Error loading recipes"))
            else
              Column(
                children: [
                  for (int i = 0;
                      i < _visibleCount && i < _allRecipes.length;
                      i++) ...[
                    _RecipeCard(
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
                      onPressed: _visibleCount < _allRecipes.length
                          ? _loadMore
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6A45),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
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
              child: data.image.isNotEmpty
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
                                  fullRecipeData: data.fullRecipeData,
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
