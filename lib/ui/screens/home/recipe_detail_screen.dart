import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';

import '../../../data/models/recipe_model.dart';
import '../../../data/services/recipe_service.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../widgets/ingredient_item.dart';
import '../../widgets/step_item.dart';
import '../../../ui/screens/recipe_detail/review_section.dart';

class RecipeDetailScreen extends StatefulWidget {
  final String recipeId;

  const RecipeDetailScreen({
    super.key,
    required this.recipeId,
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late Future<RecipeModel?> _recipeFuture;
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoadingReviews = false;
  
  @override
  void initState() {
    super.initState();
    _recipeFuture = _loadRecipe();
    
    // Load reviews immediately with template as fallback
    _loadReviews();
  }

  Future<RecipeModel?> _loadRecipe() async {
    try {
      // For now, return a mock recipe since we don't have the actual service implementation
      return RecipeModel(
        id: widget.recipeId,
        title: 'Delicious Recipe',
        cuisine: 'Italian',
        cookTime: '30',
        image: 'https://via.placeholder.com/300x200',
        description: 'A delicious recipe description',
        servings: 4,
        calories: 500,
        ingredients: [
          '2 cups flour',
          '1 cup sugar',
          '1/2 cup butter'
        ],
        instructions: [
          'Preheat oven to 350°F',
          'Mix all ingredients',
          'Bake for 30 minutes'
        ],
      );
    } catch (e) {
      debugPrint('Error loading recipe: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<RecipeModel?>(
        future: _recipeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Failed to load recipe'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _recipeFuture = _loadRecipe();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final recipe = snapshot.data!;
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    recipe.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: Offset(1, 1),
                          blurRadius: 3.0,
                          color: Colors.black45,
                        ),
                      ],
                    ),
                  ),
                  background: Hero(
                    tag: 'recipe_${recipe.id}',
                    child: CachedNetworkImage(
                      imageUrl: recipe.image,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.error),
                      ),
                    ),
                  ),
                ),
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Recipe Meta
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMetaItem(
                            Icons.timer_outlined,
                            '${recipe.cookTime} min',
                          ),
                          _buildMetaItem(
                            Icons.restaurant_menu_outlined,
                            '${recipe.servings} servings',
                          ),
                          _buildMetaItem(
                            Icons.local_fire_department_outlined,
                            '${recipe.calories} cal',
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Description
                      if (recipe.description?.isNotEmpty ?? false) ...[
                        Text(
                          'About',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          recipe.description!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                      ],
                      
                      // Ingredients
                      Text(
                        'Ingredients',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      ...recipe.ingredients.map((ingredient) => 
                        Text(ingredient, style: Theme.of(context).textTheme.bodyMedium)
                      ).toList(),
                      
                      const SizedBox(height: 24),
                      
                      // Instructions
                      Text(
                        'Instructions',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      ...recipe.instructions.asMap().entries.map((entry) => 
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            '${entry.key + 1}. ${entry.value}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        )
                      ).toList(),
                      
                      const SizedBox(height: 24),
                      
                      // Reviews Section - Using existing template with debug
                      ReviewSection(
                        reviews: _reviews,
                        recipeName: recipe.title ?? 'Recipe',
                      ),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to cooking steps with proper ingredients and image generation
          _navigateToCookingSteps();
        },
        icon: const Icon(Icons.restaurant_menu),
        label: const Text('Start Cooking'),
      ),
    );
  }

  // Load reviews for the recipe - always show template reviews
  Future<void> _loadReviews() async {
    debugPrint('🔍 Starting reviews loading for recipe: ${recipe.title ?? 'Unknown Recipe'}');
    
    if (mounted) {
      setState(() {
        _isLoadingReviews = true;
      });
    }
    
    // Always use template reviews for now
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate loading
    
    final templateReviews = _generateSimpleTemplateReviews(recipe.title ?? 'Recipe');
    debugPrint('🔍 Generated ${templateReviews.length} template reviews');
    
    if (mounted) {
      setState(() {
        _reviews = templateReviews;
        _isLoadingReviews = false;
      });
    }
    
    debugPrint('✅ Loaded ${templateReviews.length} template reviews for ${recipe.title ?? 'Recipe'}');
  }
  
  // Generate simple template reviews
  List<Map<String, dynamic>> _generateSimpleTemplateReviews(String recipeName) {
    return [
      {
        'name': 'Sarah Johnson',
        'rating': 5,
        'comment': 'This $recipeName recipe was absolutely delicious! The instructions were clear and the flavors were perfectly balanced. Will definitely make this again!',
        'timeAgo': '2 days ago',
        'verified': true,
      },
      {
        'name': 'Mike Chen',
        'rating': 4,
        'comment': 'Great recipe! I made a few substitutions based on what I had available, and it still turned out wonderful. Perfect for weeknight dinners.',
        'timeAgo': '1 week ago',
        'verified': true,
      },
      {
        'name': 'Emily Rodriguez',
        'rating': 5,
        'comment': 'Amazing $recipeName! My family loved it. Even the kids who are usually picky eaters asked for seconds. Highly recommend!',
        'timeAgo': '2 weeks ago',
        'verified': false,
      },
      {
        'name': 'David Kim',
        'rating': 4,
        'comment': 'Solid recipe with great results. I appreciate the detailed steps and helpful tips. Will become a regular in our meal rotation.',
        'timeAgo': '3 weeks ago',
        'verified': true,
      },
    ];
  }
  
  Widget _buildMetaItem(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Navigate to cooking steps without image generation
  void _navigateToCookingSteps() {
    debugPrint('🍳 Starting cooking steps navigation for: ${recipe.title}');
    
    // Use ingredients directly without image generation
    final List<Map<String, dynamic>> ingredientsToPass = recipe.ingredients.map((ingredient) => {
      'item': ingredient,
      'quantity': '1',
      'image_url': '', 
    }).toList();
    
    // Create cooking steps
    final List<Map<String, dynamic>> cookingSteps = recipe.instructions.map((instruction) => {
      'instruction': instruction,
      'ingredients_used': [], 
      'tips': [],
    }).toList();
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CookingStepsScreen(
          steps: cookingSteps,
          currentStep: 1,
          allIngredients: ingredientsToPass,
          recipeName: recipe.title,
        ),
      ),
    );
  }
}
