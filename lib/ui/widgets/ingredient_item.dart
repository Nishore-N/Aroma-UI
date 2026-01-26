import 'package:flutter/material.dart';
import 'package:aroma/data/models/ingredient_model.dart';

class IngredientItem extends StatelessWidget {
  final IngredientModel ingredient;
  final VoidCallback? onTap;
  final bool isSelected;
  final double size;

  const IngredientItem({
    Key? key,
    required this.ingredient,
    this.onTap,
    this.isSelected = false,
    this.size = 56.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).colorScheme.primary 
                : Colors.grey.shade200,
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Row(
          children: [
            // Ingredient Image or Icon
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4.0,
                    offset: const Offset(0, 2),
                  ),
                ],
                image: ingredient.emoji != null
                    ? DecorationImage(
                        image: NetworkImage(ingredient.emoji!), 
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: ingredient.emoji == null
                  ? Icon(
                      Icons.fastfood,
                      size: size * 0.5,
                      color: Colors.grey.shade400,
                    )
                  : null,
            ),
            const SizedBox(width: 12.0),
            // Ingredient Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    ingredient.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (ingredient.quantity > 0)
                    Text(
                      '${ingredient.quantity} ${ingredient.unit}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                ],
              ),
            ),
            // Checkbox or Action
            if (onTap != null)
              Icon(
                isSelected ? Icons.check_circle : Icons.add_circle_outline,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
              ),
          ],
        ),
      ),
    );
  }
}
