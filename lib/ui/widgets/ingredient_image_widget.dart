import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
              child: Builder(
                builder: (context) {
                  String finalUrl = imageUrl!;
                  if (finalUrl.startsWith('http://') && finalUrl.contains('s3')) {
                    finalUrl = finalUrl.replaceFirst('http://', 'https://');
                  }
                  
                  return CachedNetworkImage(
                    imageUrl: finalUrl,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.grey[200]),
                    errorWidget: (context, url, error) => _buildFallback(),
                  );
                }
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
