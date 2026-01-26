import 'package:flutter/material.dart';

class IngredientThumbnail extends StatelessWidget {
  final String ingredientName;
  final double size;
  final String? imageUrl;

  const IngredientThumbnail({
    super.key,
    required this.ingredientName,
    this.size = 56,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(size * 0.2),
      ),
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(size * 0.2),
              child: Image.network(
                imageUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildFallback(),
              ),
            )
          : _buildFallback(),
    );
  }

  Widget _buildFallback() {
    return Center(
      child: Icon(
        Icons.restaurant_menu,
        size: size * 0.6,
        color: Colors.grey.shade400,
      ),
    );
  }
}

class IngredientImageThumbnail extends IngredientThumbnail {
  const IngredientImageThumbnail({
    super.key,
    required super.ingredientName,
    super.size,
    super.imageUrl,
  });
}
