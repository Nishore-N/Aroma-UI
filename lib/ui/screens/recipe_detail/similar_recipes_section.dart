import 'package:flutter/material.dart';

class SimilarRecipesSection extends StatelessWidget {
  final List<Map<String, dynamic>> recipes;

  const SimilarRecipesSection({
    super.key,
    required this.recipes,
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
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              "AI is finding similar recipes...",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.orange,
              ),
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
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),

        const SizedBox(height: 18),

        /// ---- GRID ----
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recipes.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 18,
            childAspectRatio: 0.68,
          ),
          itemBuilder: (context, index) {
            final recipe = recipes[index];
            final title = recipe["title"] ?? "Recipe";

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// ---- IMAGE PLACEHOLDER ----
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.restaurant_menu,
                      size: 36,
                      color: Colors.grey,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                /// ---- TITLE ----
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 4),

                /// ---- SUBTEXT ----
                const Text(
                  "AI suggested",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
