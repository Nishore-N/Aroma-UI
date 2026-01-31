import 'package:flutter/material.dart';

class CookwareSection extends StatelessWidget {
  final int servings;
  final List<String> cookwareItems;

  const CookwareSection({
    super.key,
    required this.servings,
    required this.cookwareItems,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint('🍳 CookwareSection build called with ${cookwareItems.length} items: $cookwareItems');
    debugPrint('🍳 CookwareSection: cookwareItems.isEmpty = ${cookwareItems.isEmpty}');
    debugPrint('🍳 CookwareSection: cookwareItems.length = ${cookwareItems.length}');
    debugPrint('🍳 CookwareSection: cookwareItems = $cookwareItems');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// --- TITLE ---
        const Text(
          "Cookware",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),

        const SizedBox(height: 6),

        /// --- SERVINGS SUB-TEXT ---
        Text(
          "$servings ${servings == 1 ? 'serving' : 'servings'}",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),

        const SizedBox(height: 14),

        /// --- AI DATA ---
        
        if (cookwareItems.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "No cookware information available",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Items count: ${cookwareItems.length}",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          )
        else

          Text(
             cookwareItems.join(', '),
             style: TextStyle(
               fontSize: 15,
               height: 1.5,
               fontWeight: FontWeight.w400,
               color: Colors.grey.shade800,
             ),
          ),
      ],
    );
  }
}
