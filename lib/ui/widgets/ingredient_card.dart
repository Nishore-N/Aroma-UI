import 'package:flutter/material.dart';
import 'package:aroma/core/theme/app_colors.dart';
import 'package:aroma/core/utils/item_image_resolver.dart';

class IngredientCard extends StatelessWidget {
  final String name;
  final String quantity; // e.g. "1.0"
  final String? approxQuantity; // e.g. "905 gm"
  final String match;    // e.g. "95%"
  final String? imageUrl;
  final String? emoji;
  final VoidCallback? onRemove;
  final VoidCallback? onEdit; 

  const IngredientCard({
    super.key,
    required this.name,
    required this.quantity,
    this.approxQuantity,
    required this.match, 
    this.imageUrl,
    this.emoji,
    this.onRemove,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      child: Row(
        children: [
          // Image / Icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ItemImageResolver.getImageWidget(
              name,
              size: 50,
              imageUrl: imageUrl, 
            ),
          ),
          const SizedBox(width: 20),
          
          // Name, Quantity, Approx, Match
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 19,
                    color: Color(0xFF212529),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                
                // Quantity Line
                Text(
                  'Quantity: $quantity',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF6C757D), 
                    fontWeight: FontWeight.w400,
                  ),
                ),
                
                // Approx Quantity Line (Conditional)
                if (approxQuantity != null && approxQuantity!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Approx: $approxQuantity',
                    style: const TextStyle(
                      fontSize: 14, // Slightly smaller or same
                      color: Color(0xFF6C757D), 
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],

                const SizedBox(height: 4),
                
                // Match Line
                Text(
                  'match: $match',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF28A745), 
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Action Buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onEdit != null)
                GestureDetector(
                onTap: onEdit,
                  child: Container(
                    width: 40, 
                    height: 40,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFE3F2FD), 
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 20, 
                      color: Color(0xFF2196F3), 
                    ),
                  ),
                ),
                
              if (onEdit != null && onRemove != null)
                const SizedBox(width: 14),

              if (onRemove != null)
                GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFFFE5E5), 
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 20,
                      color: Color(0xFFFF6A6A), 
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
