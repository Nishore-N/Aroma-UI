import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../core/utils/item_image_resolver.dart';
import '../../../data/services/scan_bill_service.dart';

class IngredientRow extends StatelessWidget {
  final String emoji;
  final String name;
  final int matchPercent;
  final int quantity;
  final VoidCallback onRemove;
  final VoidCallback? onEdit;
  final bool useImageService;
  final String? imageUrl;

  const IngredientRow({
    super.key,
    required this.emoji,
    required this.name,
    required this.matchPercent,
    required this.quantity,
    required this.onRemove,
    this.onEdit,
    this.useImageService = true,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint("IngredientRow: name=$name, quantity=$quantity");
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          // Dynamic ingredient image/emoji - using ItemImageResolver for consistency
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ItemImageResolver.getImageWidget(
              name,
              size: 64,
              imageUrl: imageUrl, // Pass imageUrl to let resolver handle it
            ),
          ),

          const SizedBox(width: 14),

          // Name + match text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 19,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Quantity: $quantity',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black.withOpacity(0.55),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'match: $matchPercent%',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Action buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Edit button
              if (onEdit != null)
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFE3F2FD),
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 16,
                      color: Color(0xFF2196F3),
                    ),
                  ),
                ),
              
              if (onEdit != null)
                const SizedBox(width: 8),
              
              // Remove button (x)
              GestureDetector(
                onTap: onRemove,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFFE5E5),
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 16,
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
  
  // Method to fetch ingredient image - use provided URLs first
  Future<String?> _getIngredientImageFromMetrics() async {
    try {
      debugPrint("🎯 [IngredientRow] Checking imageUrl for $name: $imageUrl");
      
      // First check if imageUrl is already provided from the scan result
      if (imageUrl != null && imageUrl!.isNotEmpty) {
        debugPrint("🎯 [IngredientRow] Using provided imageUrl: $imageUrl");
        return imageUrl;
      }
      
      // No image URL provided, return null to show emoji
      debugPrint("🎯 [IngredientRow] No imageUrl provided for $name, using emoji");
      return null;
    } catch (e) {
      debugPrint(" [IngredientRow] Error getting image for $name: $e");
      return null;
    }
  }
  
  Widget _buildEmojiFallback() {
    return Center(
      child: Text(
        emoji.isNotEmpty ? emoji : ItemImageResolver.getEmojiForIngredient(name),
        style: const TextStyle(fontSize: 44),
      ),
    );
  }
}