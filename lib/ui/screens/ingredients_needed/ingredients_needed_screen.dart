import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../cooking_steps/cooking_steps_screen.dart';
import '../../../core/utils/item_image_resolver.dart';
import '../../../core/utils/recipe_formatter.dart';
import 'cookware_needed_screen.dart';

class IngredientsNeededScreen extends StatelessWidget {
  final int servings;
  final List<Map<String, dynamic>> ingredients;
  final List<Map<String, dynamic>> steps;
  final String recipeName;
  final String description;
  final String recipeImage;
  final List<String> cookware;
  final Map<String, String> initialGeneratedImages;

   const IngredientsNeededScreen({
    super.key,
    required this.servings,
    required this.ingredients,
    required this.steps,
    required this.recipeName,
    this.description = '',
    this.recipeImage = '',
    this.cookware = const [],
    this.initialGeneratedImages = const {},
  });

  Map<String, String> _extractGeneratedImages() {
    final Map<String, String> generated = Map<String, String>.from(initialGeneratedImages);
    for (var ing in ingredients) {
      final name = (ing['item'] ?? ing['name'] ?? ing['ingredient'] ?? '').toString();
      final url = ing['image_url']?.toString() ?? ing['imageUrl']?.toString() ?? ing['image']?.toString() ?? '';
      if (name.isNotEmpty && url.isNotEmpty) {
        generated[name] = url;
      }
    }
    return generated;
  }

  Widget _buildDefaultIngredientIcon() {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Image.asset(
        'assets/images/pantry/temp_pantry.png', 
        width: 64,
        height: 64,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(Icons.fastfood, size: 64, color: Colors.grey),
      ),
    );
  }

  Widget _buildDynamicIngredientIcon(Map<String, dynamic> ingredientData) {
    final ingredientName = (ingredientData['name'] ?? ingredientData['ingredient'] ?? ingredientData['item'] ?? 'Ingredient').toString();
    // Extract imageUrl from multiple possible fields for S3 URL support
    String imageUrl = ingredientData['image_url']?.toString() ?? 
                   ingredientData['imageUrl']?.toString() ?? 
                   ingredientData['image']?.toString() ?? '';
    
    // Fallback to initialGeneratedImages if missing in the list item
    if (imageUrl.isEmpty) {
      imageUrl = initialGeneratedImages[ingredientName] ?? '';
    }
    
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Builder(
        builder: (context) {
          if (imageUrl.isNotEmpty && (imageUrl.startsWith('http://') || imageUrl.startsWith('https://'))) {
             String finalUrl = imageUrl;
             if (finalUrl.startsWith('http://') && finalUrl.contains('s3')) {
                finalUrl = finalUrl.replaceFirst('http://', 'https://');
             }

            return CachedNetworkImage(
              imageUrl: finalUrl,
              width: 64,
              height: 64,
              fit: BoxFit.contain,
              placeholder: (context, url) => SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
                ),
              ),
              errorWidget: (context, url, error) => _buildEmojiIcon(ingredientName),
            );
          }
          
          return _buildEmojiIcon(ingredientName);
        },
      ),
    );
  }

  Widget _buildEmojiIcon(String ingredientName) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Text(
        ItemImageResolver.getEmojiForIngredient(ingredientName),
        style: const TextStyle(fontSize: 44),
      ),
    );
  }

  Widget _buildIngredientIcon(dynamic icon, Map<String, dynamic> ingredientData) {
    // If we have an emoji, use it
    if (icon is String && icon.isNotEmpty && !icon.startsWith('http')) {
      return Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Text(
          icon,
          style: const TextStyle(fontSize: 30),
        ),
      );
    }
    // Use dynamic ingredient image service with full data
    return _buildDynamicIngredientIcon(ingredientData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ---------------- STICKY HEADER ----------------
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
                    "Ingredients Needed",
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

                    const SizedBox(height: 20),

                    // ---------------- SERVINGS INFO ----------------
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F3F3),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.black,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                          children: [
                            const TextSpan(
                              text: "Make sure you have all ingredients for ",
                            ),
                            TextSpan(
                              text: "$servings serving",
                              style: const TextStyle(
                                color: Color(0xFFFF6A45),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    const SizedBox(height: 22),

                    // ---------------- INGREDIENTS SECTION ----------------
                    // Removed "Ingredients" title as per request to match image implicitly if needed, 
                    // but keeping it simple as per "old ui as old flow but...". 
                    // The user said "i doint need as checklist screen andd description or image just as i provided in ui image"
                    // The image provided DOES NOT show the "Ingredients" header text, just the list.
                    // However, keeping the list structure.
                    
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: ingredients.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        thickness: 0.7,
                        color: Color(0xFFE5E5E5),
                      ),
                      itemBuilder: (context, index) {
                        final item = ingredients[index];
                        final name = (item['name'] ?? item['ingredient'] ?? item['item'] ?? 'Ingredient').toString();
                        final baseQty = item['qty'] ?? item['quantity'] ?? item['amount'] ?? 'as needed';
                        final unit = item['unit']?.toString() ?? '';
                        final qty = RecipeFormatter.formatQuantity(baseQty, servings, unit);
                        final icon = item['icon'] ?? '';

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          child: Row(
                            children: [
                              _buildIngredientIcon(icon, item),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      qty,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF7A7A7A),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
                    // Existing steps processing logic
                    List<Map<String, dynamic>> stepsToPass = [];
                    if (steps.isNotEmpty) {
                      stepsToPass = steps.map((step) {
                        List<Map<String, dynamic>> processedIngredients = [];
                        if (step['ingredients_used'] != null) {
                          final ingredientsList = step['ingredients_used'] as List;
                          processedIngredients = ingredientsList.map((ing) {
                            if (ing is Map<String, dynamic>) {
                              return {
                                'item': ing['item'] ?? ing['name'] ?? ing['ingredient'] ?? 'Ingredient',
                                'quantity': ing['quantity']?.toString() ?? ing['qty']?.toString() ?? ing['amount']?.toString() ?? 'as needed',
                                'icon': ing['icon'] ?? '',
                                'image_url': ing['image_url']?.toString() ?? ing['imageUrl']?.toString() ?? ing['image']?.toString() ?? '',
                              };
                            } else {
                              return {
                                'item': ing.toString(),
                                'quantity': 'as needed',
                                'icon': '',
                                'image_url': '',
                              };
                            }
                          }).toList();
                        }
                        
                        return {
                          'instruction': step['instruction']?.toString() ?? 'Continue cooking',
                          'ingredients_used': processedIngredients,
                          'tips': (step['tips'] as List?)?.whereType<String>().toList() ?? [],
                          if (step['rich_instruction'] != null) 'rich_instruction': step['rich_instruction'],
                        };
                      }).toList();
                    } else {
                      final processedIngredients = ingredients.map((ing) {
                        return {
                          'item': ing['item'] ?? ing['name'] ?? ing['ingredient'] ?? 'Ingredient',
                          'quantity': ing['quantity']?.toString() ?? ing['qty']?.toString() ?? ing['amount']?.toString() ?? 'as needed',
                          'icon': ing['icon'] ?? '',
                          'image_url': ing['image_url']?.toString() ?? ing['imageUrl']?.toString() ?? ing['image']?.toString() ?? '',
                        };
                      }).toList();
                      
                      stepsToPass = [{
                        'instruction': 'Follow recipe instructions',
                        'ingredients_used': processedIngredients,
                        'tips': ['Make sure to follow the recipe carefully']
                      }];
                    }
                    
                    // Navigate to CookingStepsScreen directly, SKIPPING CookwareNeededScreen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CookingStepsScreen(
                          steps: stepsToPass,
                          currentStep: 1,
                          allIngredients: ingredients,
                          recipeName: recipeName,
                          servings: servings,
                          initialGeneratedImages: _extractGeneratedImages(),
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    "Lets Start",
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