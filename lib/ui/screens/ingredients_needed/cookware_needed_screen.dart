import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../cooking_steps/cooking_steps_screen.dart';

class CookwareNeededScreen extends StatelessWidget {
  final int servings;
  final List<String> cookware;
  final List<Map<String, dynamic>> ingredients;
  final List<Map<String, dynamic>> steps;
  final String recipeName;
  final String description;
  final String recipeImage;
  final Map<String, String> initialGeneratedImages;

  const CookwareNeededScreen({
    super.key,
    required this.servings,
    required this.cookware,
    required this.ingredients,
    required this.steps,
    required this.recipeName,
    this.description = '',
    this.recipeImage = '',
    this.initialGeneratedImages = const {},
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ---------------- BACK BUTTON ----------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Container(
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    "Cookware Check",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ---------------- RECIPE SUMMARY ----------------
                    if (recipeImage.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: CachedNetworkImage(
                          imageUrl: recipeImage,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    
                    const SizedBox(height: 16),
                    
                    Text(
                      recipeName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const SizedBox(height: 25),

                    // ---------------- COOKWARE SECTION ----------------
                    const Text(
                      "What You'll Need",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (cookware.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Text(
                          "No specific cookware listed. Standard kitchen tools should suffice.",
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: cookware.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEFE5),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.restaurant_menu, color: Color(0xFFFF6A45)),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    cookware[index],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.check_circle_outline, color: Colors.orange),
                              ],
                            ),
                          );
                        },
                      ),
                    
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),

            // ---------------- BOTTOM BUTTON ----------------
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6A45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    // Navigate to actual cooking steps
                     Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CookingStepsScreen(
                          steps: steps,
                          currentStep: 1,
                          allIngredients: ingredients,
                          recipeName: recipeName,
                          servings: servings,
                          initialGeneratedImages: initialGeneratedImages,
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    "Let's Start Cooking",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
