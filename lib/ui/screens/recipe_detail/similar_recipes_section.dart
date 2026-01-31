import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SimilarRecipesSection extends StatelessWidget {
  final List<Map<String, dynamic>> recipes;
  final Function(Map<String, dynamic>) onRecipeTap;

  const SimilarRecipesSection({
    super.key,
    required this.recipes,
    required this.onRecipeTap,
  });

  @override
  Widget build(BuildContext context) {
    if (recipes.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "More recipes like this",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: const Column(
              children: [
                CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Color(0xFFFF6A45)),
                ),
                SizedBox(height: 12),
                Text(
                  "Finding more recipes for you...",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// ---- TITLE ----
        const Text(
          "More recipes like this",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Color(0xFF212529),
          ),
        ),

        const SizedBox(height: 20),

        /// ---- GRID ----
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recipes.length > 4 ? 4 : recipes.length, // Limit to 4 for details screen
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 24,
            childAspectRatio: 0.65,
          ),
          itemBuilder: (context, index) {
            final recipe = recipes[index];
            
            // Extract data with fallbacks
            final title = recipe["recipe_name"] ?? recipe["name"] ?? recipe["title"] ?? "Recipe";
            final image = recipe["recipe_image_url"] ?? recipe["image_url"] ?? recipe["image"] ?? "";
            final cuisine = recipe["cuisine"] ?? "Indian";
            
            // Fix: ensure "min" label is present
            String rawTime = (recipe["cooking_time"] ?? recipe["cook_time"] ?? recipe["time"] ?? "30-40").toString();
            String displayTime = rawTime.replaceAll("minutes", "min").replaceAll("mins", "min").replaceAll("minute", "min");
            if (!displayTime.contains("min") && !displayTime.contains("h")) {
              displayTime = "$displayTime min";
            }

            debugPrint('🎨 [SimilarRecipesSection] Item $index: title=$title, time=$displayTime, hasImage=${image.isNotEmpty}');
            if (image.isNotEmpty) debugPrint('🖼️ [SimilarRecipesSection] Image URL: $image');
            
            return GestureDetector(
              onTap: () => onRecipeTap(recipe),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// ---- IMAGE WITH HEART ----
                  Expanded(
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: image.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: image,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: Colors.grey.shade100,
                                    child: const Center(
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: Colors.grey.shade100,
                                    child: const Icon(Icons.restaurant, color: Colors.grey),
                                  ),
                                )
                              : Container(
                                  color: Colors.grey.shade100,
                                  child: const Icon(Icons.restaurant, color: Colors.grey),
                                ),
                        ),
                        
                        // Heart Icon Overlay
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.favorite_border,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// ---- RECIPE NAME ----
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF212529),
                    ),
                  ),

                  const SizedBox(height: 4),

                  /// ---- SOURCE/CUISINE ----
                  Row(
                    children: [
                      const Text(
                        "Gen-AI",
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFFFF6A45),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text("•", style: TextStyle(color: Colors.grey)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          cuisine,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  /// ---- TIME & STAS ----
                  Row(
                    children: [
                      Text(
                        displayTime,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text("•", style: TextStyle(color: Colors.grey)),
                      const SizedBox(width: 6),
                      const Text(
                        "100 times",
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFFF6A45),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
