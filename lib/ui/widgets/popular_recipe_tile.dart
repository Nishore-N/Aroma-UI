import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/recipe_model.dart';
import '../../state/home_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PopularRecipeTile extends StatelessWidget {
  const PopularRecipeTile({super.key, required this.recipe, this.isLarge = false});

  final RecipeModel recipe;
  final bool isLarge;

  @override
  Widget build(BuildContext context) {
    const double smallAspectRatio = 4 / 3; // wider, shorter
    const double largeAspectRatio = 3 / 4; // taller card
    final double aspectRatio = isLarge ? largeAspectRatio : smallAspectRatio;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            CachedNetworkImage(
              imageUrl: recipe.image,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: Colors.grey[200]),
              errorWidget: (context, url, error) =>
                  Container(color: Colors.grey[300]),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Colors.black.withOpacity(0.05),
                    Colors.black.withOpacity(0.75),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: () {
                  context.read<HomeProvider>().toggleSaved(recipe.id);
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.25),
                  ),
                  child: Icon(
                    recipe.isSaved ? Icons.favorite : Icons.favorite_border,
                    size: 16,
                    color: recipe.isSaved ? Colors.redAccent : Colors.white,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Text(
                    recipe.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recipe.cuisine,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${recipe.cookTime} min',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
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
