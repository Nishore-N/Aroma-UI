import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/utils/item_image_resolver.dart';
import '../../../core/utils/recipe_formatter.dart';

class StepIngredientsBottomSheet extends StatelessWidget {
  final List<Map<String, dynamic>> stepIngredients;
  final List<Map<String, dynamic>>? allIngredients;
  final int? currentStepIndex;
  final int servings;
  final Map<String, String> locallyGeneratedImages; // Add this
  bool get showAllIngredients => allIngredients != null && currentStepIndex != null;

  const StepIngredientsBottomSheet({
    super.key,
    required this.stepIngredients,
    this.allIngredients,
    this.currentStepIndex,
    this.servings = 4,
    this.locallyGeneratedImages = const {}, // Add this
  });

  // ... (rest of the class)

  Widget _buildIngredientIcon(dynamic icon, String ingredientName) {
    if (icon is String && icon.isNotEmpty && (icon.startsWith('http://') || icon.startsWith('https://'))) {
      String imageUrl = icon;
      if (imageUrl.startsWith('http://') && imageUrl.contains('s3')) {
          imageUrl = imageUrl.replaceFirst('http://', 'https://');
      }

      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(color: Colors.grey[200]),
            errorWidget: (context, url, error) => ItemImageResolver.getImageWidget(ingredientName, size: 48),
          ),
        ),
      );
    }
    
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: ItemImageResolver.getImageWidget(ingredientName, size: 30),
      ),
    );
  }

  Widget _buildEmojiIcon(String ingredientName) {
    return Text(
      ItemImageResolver.getEmojiForIngredient(ingredientName),
      style: const TextStyle(fontSize: 30),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        /// =================== WHITE SHEET ===================
        Container(
          margin: const EdgeInsets.only(top: 60),
          padding: const EdgeInsets.fromLTRB(20, 38, 20, 30),
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// TITLE & TOGGLE
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    showAllIngredients ? "All Ingredients" : "Ingredients for This Step",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                  if (allIngredients != null)
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => StepIngredientsBottomSheet(
                            stepIngredients: stepIngredients,
                            allIngredients: showAllIngredients ? null : allIngredients,
                            currentStepIndex: showAllIngredients ? null : currentStepIndex,
                            servings: servings,
                            locallyGeneratedImages: locallyGeneratedImages,
                          ),
                        );
                      },
                      child: Text(
                        showAllIngredients ? "Show This Step Only" : "Show All Ingredients",
                        style: const TextStyle(
                          color: Color(0xFFFF6A45),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 20),

              /// ================= INGREDIENT BOX LIST =================
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: SingleChildScrollView(
                  child: Column(
                    children: (showAllIngredients ? allIngredients! : stepIngredients).map<Widget>(
                      (item) {
                        final name = (item['item'] ?? 'Ingredient').toString();
                        final baseQty = item['quantity'] ?? item['qty'] ?? '';
                        final unit = item['unit']?.toString() ?? '';
                        final qty = RecipeFormatter.formatQuantity(baseQty, servings, unit);
                        
                        var imageUrl = item['image_url']?.toString() ?? 
                                       item['imageUrl']?.toString() ?? 
                                       item['image']?.toString() ?? '';
                        
                        if (imageUrl.isEmpty) {
                          imageUrl = locallyGeneratedImages[name] ?? '';
                        }
                        
                        if (imageUrl.isEmpty && allIngredients != null) {
                          for (final allIng in allIngredients!) {
                            final allName = (allIng['item'] ?? allIng['name'] ?? '').toString().toLowerCase().trim();
                            final currentName = name.toLowerCase().trim();
                            if (allName == currentName || currentName.contains(allName) || allName.contains(currentName)) {
                              imageUrl = allIng['image_url']?.toString() ?? 
                                         allIng['imageUrl']?.toString() ?? 
                                         allIng['image']?.toString() ?? '';
                              break;
                            }
                          }
                        }
                        
                        final icon = imageUrl.isNotEmpty ? imageUrl : (item['icon'] as String? ?? '');

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFFFDCCD),
                              width: 1.6,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              _buildIngredientIcon(icon, name),
                              const SizedBox(width: 14),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.black,
                                      ),
                                    ),
                                    if (qty.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        qty,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),

        /// =================== CLOSE ❌ BUTTON ===================
        Positioned(
          top: 4,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              height: 46,
              width: 46,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }
}