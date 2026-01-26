import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/recipe_model.dart';
import '../../state/home_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../screens/recipe_detail/recipe_detail_screen.dart';

class ExplorePopularChoiceCard extends StatelessWidget {
  const ExplorePopularChoiceCard({
    super.key,
    required this.recipe,
    required this.isLeftCard,
  });

  final RecipeModel recipe;
  final bool isLeftCard;

  @override
  Widget build(BuildContext context) {
    // Fixed dimensions as requested
    final double cardWidth = isLeftCard ? 160.0 : 159.0;
    final double cardHeight = isLeftCard ? 199.0 : 312.0;

    return GestureDetector(
      onTap: () {
        // Navigate to recipe detail
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailScreen(
              image: recipe.image,
              title: recipe.title,
              ingredients: recipe.ingredients.map((ingredient) => {
                'name': ingredient,
                'quantity': '1',
                'unit': 'unit'
              }).toList(),
              cuisine: recipe.cuisine,
              cookTime: recipe.cookTime,
              servings: recipe.servings,
              fullRecipeData: recipe.fullRecipeData ?? {},
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card image with favorite button
          SizedBox(
            width: cardWidth,
            height: cardHeight - 40, // Reduce height to make space for text
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  // Background image
                  CachedNetworkImage(
                    imageUrl: recipe.image,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.grey[200]),
                    errorWidget: (context, url, error) => Container(color: Colors.grey[300]),
                  ),
                  // Favorite button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        context.read<HomeProvider>().toggleSaved(recipe.id);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.9),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          recipe.isSaved ? Icons.favorite : Icons.favorite_border,
                          size: 20,
                          color: recipe.isSaved ? Colors.redAccent : Colors.black54,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Recipe information outside the card
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF212529),
                    fontSize: isLeftCard ? 14 : 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Gen-AI • ${recipe.cuisine}',
                  style: TextStyle(
                    color: const Color(0xFFFE734C),
                    fontSize: isLeftCard ? 12 : 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
