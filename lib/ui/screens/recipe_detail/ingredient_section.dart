import 'package:flutter/material.dart';
import '../../../core/utils/recipe_formatter.dart';
import '../../../ui/widgets/ingredient_image_widget.dart';
import '../../../core/utils/item_image_resolver.dart';
import '../../../data/services/recipe_detail_service.dart';

// ===============================
// INGREDIENT SECTION (DYNAMIC)
// ===============================
class IngredientSection extends StatefulWidget {
  final int servings;
  final Function(int) onServingChange;
  final List<Map<String, dynamic>> ingredientData; // scanned bill
  final List<String> availableIngredients;
  final Function(String, String)? onImageGenerated; // Add callback

  const IngredientSection({
    super.key,
    required this.servings,
    required this.onServingChange,
    required this.ingredientData,
    this.availableIngredients = const [],
    this.onImageGenerated,
  });

  @override
  State<IngredientSection> createState() => _IngredientSectionState();
}

class _IngredientSectionState extends State<IngredientSection> {

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Ingredients",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 14),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "${widget.servings} Servings",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            IngredientStepper(
              servings: widget.servings,
              onChanged: widget.onServingChange,
            ),
          ],
        ),

        const SizedBox(height: 22),

        Column(
          children: widget.ingredientData.map((item) {
            final name = item['item']?.toString() ?? '';
            final qty = item['quantity'] ?? item['qty'] ?? 1;
            final unit = item['unit']?.toString() ?? '';
            final imageUrl = item['image_url']?.toString() ?? 
                           item['imageUrl']?.toString() ?? 
                           item['image']?.toString() ?? '';

            return IngredientTile(
              name: name,
              quantity: RecipeFormatter.formatQuantity(qty, widget.servings, unit),
              icon: '',
              isAvailable:
                  widget.availableIngredients.contains(name.toLowerCase()),
              imageUrl: imageUrl, // Use the image URL passed from parent
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ===============================
// INGREDIENT TILE
// ===============================
class IngredientTile extends StatelessWidget {
  final String name;
  final String quantity;
  final String icon;
  final bool isAvailable;
  final String? imageUrl; // Add imageUrl parameter

  const IngredientTile({
    super.key,
    required this.name,
    required this.quantity,
    required this.icon,
    this.isAvailable = false,
    this.imageUrl, // Add to constructor
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
          )
        ],
      ),
      child: Row(
        children: [
          // Dynamic ingredient image with MongoDB-first caching
          IngredientImageThumbnail(
            ingredientName: name,
            size: 64,
            imageUrl: imageUrl, // Pass the backend S3 URL
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  "Qty: $quantity",
                  style: TextStyle(
                    color: Colors.orange.shade600,
                    fontSize: 13,
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

// ===============================
// SERVING STEPPER
// ===============================
class IngredientStepper extends StatelessWidget {
  final int servings;
  final Function(int) onChanged;

  const IngredientStepper({
    super.key,
    required this.servings,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 55,
      width: 194,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFA58A),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => onChanged(servings > 1 ? servings - 1 : 1),
            child: _btn("−"),
          ),
          Expanded(
            child: Center(
              child: Text(
                "$servings",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => onChanged(servings + 1),
            child: _btn("+"),
          ),
        ],
      ),
    );
  }

  Widget _btn(String text) {
    return Container(
      width: 55,
      height: 45,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2EC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Color(0xFFFF6A45),
          ),
        ),
      ),
    );
  }
}
