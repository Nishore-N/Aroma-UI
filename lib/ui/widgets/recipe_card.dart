import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../screens/add_ingredients/capture_preview_screen.dart';
import '../screens/recipe_detail/recipe_detail_screen.dart';
import '../../data/models/recipe_model.dart';
import '../../state/home_provider.dart';
import '../../core/enums/scan_mode.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Custom SVG widget for Gen AI icon
class GenAiIcon extends StatelessWidget {
  const GenAiIcon({super.key, this.size = 16, this.color = Colors.white70});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size), // Square aspect ratio for new icon
      painter: _GenAiIconPainter(color),
    );
  }
}

// Custom SVG widget for Restaurant Type icon (fork and knife)
class RestaurantTypeIcon extends StatelessWidget {
  const RestaurantTypeIcon({super.key, this.size = 16, this.color = Colors.white70});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size), // Square aspect ratio
      painter: _RestaurantTypeIconPainter(color),
    );
  }
}

// Custom SVG widget for Timer icon (hourglass with people)
class TimerIcon extends StatelessWidget {
  const TimerIcon({super.key, this.size = 16, this.color = Colors.white70});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size), // Square aspect ratio
      painter: _TimerIconPainter(color),
    );
  }
}

class _GenAiIconPainter extends CustomPainter {
  _GenAiIconPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 16;

    // Scale the SVG paths to fit the container
    canvas.translate(0, 0);
    canvas.scale(scale, scale);

    // Draw white rounded background
    final backgroundPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final backgroundPath = Path();
    backgroundPath.addRRect(RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, 16, 16),
      const Radius.circular(4),
    ));
    canvas.drawPath(backgroundPath, backgroundPaint);

    // Draw the chef hat icon
    final paint = Paint()
      ..color = const Color(0xFF333333)
      ..style = PaintingStyle.fill;

    final path = Path();
    
    // Top part of chef hat (puffy part)
    path.moveTo(11.75, 3.25);
    path.cubicTo(12.9922, 3.25, 14, 4.25781, 14, 5.5);
    path.cubicTo(14, 6.48438, 12.5, 10, 12.5, 10);
    path.lineTo(10.7422, 10);
    path.lineTo(11.3516, 6.32031);
    path.cubicTo(11.3984, 6.10938, 11.2578, 5.92188, 11.0469, 5.89844);
    path.cubicTo(10.8594, 5.85156, 10.6484, 5.99219, 10.625, 6.20312);
    path.lineTo(9.99219, 10);
    path.lineTo(8.375, 10);
    path.lineTo(8.375, 6.25);
    path.cubicTo(8.375, 6.0625, 8.1875, 5.875, 8, 5.875);
    path.cubicTo(7.78906, 5.875, 7.625, 6.0625, 7.625, 6.25);
    path.lineTo(7.625, 10);
    path.lineTo(5.98438, 10);
    path.lineTo(5.35156, 6.20312);
    path.cubicTo(5.32812, 5.99219, 5.11719, 5.85156, 4.92969, 5.89844);
    path.cubicTo(4.71875, 5.92188, 4.57812, 6.10938, 4.625, 6.32031);
    path.lineTo(5.23438, 10);
    path.lineTo(3.5, 10);
    path.cubicTo(3.5, 10, 2, 6.48438, 2, 5.5);
    path.cubicTo(1.97656, 4.65625, 2.46875, 3.88281, 3.24219, 3.48438);
    path.cubicTo(3.99219, 3.10938, 4.90625, 3.20312, 5.58594, 3.71875);
    path.cubicTo(6.14844, 2.99219, 7.01562, 2.5, 8, 2.5);
    path.cubicTo(8.98438, 2.5, 9.82812, 2.99219, 10.3906, 3.71875);
    path.cubicTo(10.7656, 3.41406, 11.2578, 3.27344, 11.75, 3.25);
    path.close();

    // Bottom band of chef hat
    path.moveTo(3.5, 13.75);
    path.lineTo(3.5, 10.75);
    path.lineTo(12.5, 10.75);
    path.lineTo(12.5, 13.75);
    path.cubicTo(12.5, 14.1719, 12.1484, 14.5, 11.75, 14.5);
    path.lineTo(4.25, 14.5);
    path.cubicTo(3.82812, 14.5, 3.5, 14.1719, 3.5, 13.75);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RestaurantTypeIconPainter extends CustomPainter {
  _RestaurantTypeIconPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 16;

    // Scale the SVG paths to fit the container
    canvas.translate(0, 0);
    canvas.scale(scale, scale);

    // Draw white rounded background
    final backgroundPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final backgroundPath = Path();
    backgroundPath.addRRect(RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, 16, 16),
      const Radius.circular(4),
    ));
    canvas.drawPath(backgroundPath, backgroundPaint);

    // Draw the fork and knife icon
    final paint = Paint()
      ..color = const Color(0xFF333333)
      ..style = PaintingStyle.fill;

    final path = Path();
    
    // Fork (left side)
    path.moveTo(7.22656, 2.78125);
    path.lineTo(7.92969, 5.3125);
    path.cubicTo(8.09375, 6.10938, 7.90625, 6.92969, 7.41406, 7.53906);
    path.cubicTo(7.10938, 7.89062, 6.75781, 8.14844, 6.33594, 8.3125);
    path.lineTo(6.5, 13.9375);
    path.cubicTo(6.5, 14.0781, 6.42969, 14.2422, 6.33594, 14.3359);
    path.cubicTo(6.21875, 14.4531, 6.07812, 14.5, 5.9375, 14.5);
    path.lineTo(4.8125, 14.5);
    path.cubicTo(4.64844, 14.5, 4.50781, 14.4531, 4.39062, 14.3359);
    path.cubicTo(4.29688, 14.2422, 4.22656, 14.0781, 4.25, 13.9375);
    path.lineTo(4.39062, 8.3125);
    path.cubicTo(3.96875, 8.14844, 3.61719, 7.89062, 3.3125, 7.53906);
    path.cubicTo(2.82031, 6.92969, 2.63281, 6.10938, 2.79688, 5.33594);
    path.lineTo(3.5, 2.78125);
    path.cubicTo(3.54688, 2.61719, 3.73438, 2.47656, 3.92188, 2.52344);
    path.cubicTo(4.10938, 2.54688, 4.25, 2.71094, 4.25, 2.89844);
    path.lineTo(4.25, 6.27344);
    path.lineTo(4.64844, 6.27344);
    path.lineTo(5, 2.85156);
    path.cubicTo(5, 2.66406, 5.16406, 2.52344, 5.375, 2.52344);
    path.cubicTo(5.5625, 2.52344, 5.72656, 2.66406, 5.72656, 2.85156);
    path.lineTo(6.07812, 6.27344);
    path.lineTo(6.5, 6.27344);
    path.lineTo(6.5, 2.89844);
    path.cubicTo(6.5, 2.71094, 6.61719, 2.54688, 6.80469, 2.52344);
    path.cubicTo(7.01562, 2.47656, 7.17969, 2.61719, 7.22656, 2.78125);
    path.close();

    // Knife (right side)
    path.moveTo(12.6641, 2.52344);
    path.cubicTo(12.9922, 2.52344, 13.25, 2.75781, 13.25, 3.08594);
    path.lineTo(13.25, 13.9609);
    path.cubicTo(13.25, 14.2656, 12.9922, 14.5, 12.6641, 14.5);
    path.lineTo(11.5391, 14.5);
    path.cubicTo(11.3984, 14.5, 11.2578, 14.4531, 11.1406, 14.3359);
    path.cubicTo(11.0469, 14.2188, 10.9766, 14.0781, 11, 13.9141);
    path.lineTo(11.2344, 9.57812);
    path.cubicTo(7.15625, 5.96875, 11.3516, 2.52344, 12.6641, 2.52344);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TimerIconPainter extends CustomPainter {
  _TimerIconPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 16;

    // Scale the SVG paths to fit the container
    canvas.translate(0, 0);
    canvas.scale(scale, scale);

    // Draw white rounded background
    final backgroundPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final backgroundPath = Path();
    backgroundPath.addRRect(RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, 16, 16),
      const Radius.circular(4),
    ));
    canvas.drawPath(backgroundPath, backgroundPaint);

    // Draw the hourglass with people icon
    final paint = Paint()
      ..color = const Color(0xFF333333)
      ..style = PaintingStyle.fill;

    final path = Path();
    
    // First person (top)
    path.moveTo(7, 4);
    path.cubicTo(6.57812, 4, 6.25, 3.67188, 6.25, 3.25);
    path.cubicTo(6.25, 2.85156, 6.57812, 2.5, 7, 2.5);
    path.cubicTo(7.39844, 2.5, 7.75, 2.85156, 7.75, 3.25);
    path.cubicTo(7.75, 3.67188, 7.39844, 4, 7, 4);
    path.close();

    // Hourglass body
    path.moveTo(13.1875, 7.375);
    path.lineTo(12.6953, 7.375);
    path.cubicTo(13.3516, 8.42969, 13.75, 9.55469, 13.75, 10.4688);
    path.cubicTo(13.75, 11.2422, 13.4688, 11.9453, 13, 12.5547);
    path.lineTo(13, 13.9375);
    path.cubicTo(13, 14.2656, 12.7422, 14.5, 12.4375, 14.5);
    path.cubicTo(12.1094, 14.5, 11.875, 14.2656, 11.875, 13.9375);
    path.lineTo(11.875, 13.5625);
    path.cubicTo(10.9609, 14.1484, 9.76562, 14.5, 8.5, 14.5);
    path.cubicTo(7.21094, 14.5, 6.01562, 14.1484, 5.125, 13.5625);
    path.lineTo(5.125, 13.9375);
    path.cubicTo(5.125, 14.2656, 4.86719, 14.5, 4.5625, 14.5);
    path.cubicTo(4.23438, 14.5, 4, 14.2656, 4, 13.9375);
    path.lineTo(4, 12.5547);
    path.cubicTo(3.50781, 11.9453, 3.25, 11.2422, 3.25, 10.4688);
    path.cubicTo(3.25, 9.55469, 3.625, 8.42969, 4.28125, 7.375);
    path.lineTo(3.8125, 7.375);
    path.cubicTo(3.48438, 7.375, 3.25, 7.14062, 3.25, 6.8125);
    path.cubicTo(3.25, 6.50781, 3.48438, 6.25, 3.8125, 6.25);
    path.lineTo(13.1875, 6.25);
    path.cubicTo(13.4922, 6.25, 13.75, 6.50781, 13.75, 6.8125);
    path.cubicTo(13.75, 7.14062, 13.4922, 7.375, 13.1875, 7.375);
    path.close();

    // Hourglass center
    path.moveTo(8.5, 13.375);
    path.cubicTo(10.7734, 13.375, 12.625, 12.0859, 12.625, 10.4688);
    path.cubicTo(12.625, 9.64844, 12.1094, 8.40625, 11.3125, 7.375);
    path.lineTo(5.66406, 7.375);
    path.cubicTo(4.86719, 8.40625, 4.375, 9.64844, 4.375, 10.4688);
    path.cubicTo(4.375, 12.0859, 6.20312, 13.375, 8.5, 13.375);
    path.close();

    // Second person (bottom)
    path.moveTo(9.625, 5.5);
    path.cubicTo(8.99219, 5.5, 8.5, 5.00781, 8.5, 4.375);
    path.cubicTo(8.5, 3.76562, 8.99219, 3.25, 9.625, 3.25);
    path.cubicTo(10.2344, 3.25, 10.75, 3.76562, 10.75, 4.375);
    path.cubicTo(10.75, 5.00781, 10.2344, 5.5, 9.625, 5.5);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


class RecipeCard extends StatelessWidget {
  const RecipeCard({super.key, required this.recipe, this.isActive = false});

  final RecipeModel recipe;
  final bool isActive;

  // Navigate to recipe detail screen
  void _navigateToRecipeDetail(BuildContext context, RecipeModel recipe) {
    debugPrint('🏠 [RecipeCard] "Cook now" clicked for recipe: ${recipe.title}');
    
    // Stop any ongoing background image generation to prioritize this navigation
    try {
      context.read<HomeProvider>().stopImageGeneration();
    } catch (e) {
      debugPrint('⚠️ [RecipeCard] Could not stop image generation: $e');
    }

    debugPrint('🏠 [RecipeCard] Recipe ID: ${recipe.id}');
    
    // Pass the existing fullRecipeData directly. If it's null, RecipeDetailScreen will fetch it.
    final fullRecipeData = recipe.fullRecipeData;

    debugPrint('🏠 [RecipeCard] Full recipe data keys: ${fullRecipeData?.keys.join(', ') ?? "NULL"}');

    // Convert string ingredients to Map format for RecipeDetailScreen
    final rawIngredients = fullRecipeData?['ingredients'] as List<dynamic>?;
    final List<Map<String, dynamic>> ingredientMaps = [];

    if (rawIngredients != null) {
      for (var ing in rawIngredients) {
        if (ing is Map<String, dynamic>) {
          ingredientMaps.add(ing);
        } else if (ing is String) {
          ingredientMaps.add({
            'item': ing,
            'quantity': '1',
          });
        }
      }
    }

    if (ingredientMaps.isEmpty && recipe.ingredients.isNotEmpty) {
       ingredientMaps.addAll(recipe.ingredients.map((ingredient) => {
          'item': ingredient,
          'quantity': '1',
        }));
    }

    debugPrint('🏠 [RecipeCard] Navigating to RecipeDetailScreen with ${ingredientMaps.length} ingredients');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailScreen(
          recipeId: recipe.id,
          image: recipe.image,
          title: recipe.title,
          ingredients: ingredientMaps,
          cuisine: recipe.cuisine,
          cookTime: recipe.cookTime,
          servings: recipe.servings,
          fullRecipeData: fullRecipeData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: AspectRatio(
        aspectRatio: 306/458, // New aspect ratio from SVG
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            // Background image from backend URL with caching
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: CachedNetworkImage(
                imageUrl: recipe.image,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                placeholder: (context, url) => Container(color: Colors.grey[200]),
                errorWidget: (context, url, error) => Container(color: Colors.grey[300]),
              ),
            ),

            // Top-left badge
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFFFFD54F) : Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  "Today's special",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isActive ? Colors.black : Colors.black87,
                  ),
                ),
              ),
            ),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Text(
                  recipe.title,
                  style: GoogleFonts.figtree(
                    color: const Color(0xFFFFFFFF),
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: <Widget>[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const GenAiIcon(
                          size: 16,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Gen-AI',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const RestaurantTypeIcon(
                          size: 16,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          recipe.cuisine,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const TimerIcon(
                          size: 16,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.cookTime} min',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _navigateToRecipeDetail(context, recipe);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Cook now'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          context.read<HomeProvider>().toggleSaved(recipe.id);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              recipe.isSaved ? Colors.redAccent : Colors.white,
                          side: BorderSide(
                            color: recipe.isSaved
                                ? Colors.redAccent
                                : Colors.white70,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.5),
                          ),
                          backgroundColor: Colors.white.withOpacity(0.2),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              recipe.isSaved
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 18,
                              color: recipe.isSaved
                                  ? Colors.redAccent
                                  : const Color(0xFFB3A8A8),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Save',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
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
          ),
          ],
        ),
      ),
    );
  }
}

