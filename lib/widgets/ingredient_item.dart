import 'package:flutter/material.dart';

class IngredientItem extends StatelessWidget {
  final String ingredient;

  const IngredientItem({Key? key, required this.ingredient}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.circle, size: 8, color: Theme.of(context).primaryColor),
      title: Text(
        ingredient,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
