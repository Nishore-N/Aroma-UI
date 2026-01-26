import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../state/pantry_state.dart';
import '../../../data/services/shopping_list_service.dart';
import '../../../data/services/ingredient_metrics_service.dart';
import '../../../core/utils/item_image_resolver.dart';
import '../../../ui/widgets/ingredient_row.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({Key? key}) : super(key: key);

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final IngredientMetricsService _metricsService = IngredientMetricsService();
  bool _metricsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    await _metricsService.loadMetrics();
    setState(() {
      _metricsLoaded = true;
    });
  }

  // ---------------- EDIT ITEM ----------------
  Future<void> _editItem(String name, String currentQuantity, String currentUnit) async {
    final quantityController = TextEditingController(text: currentQuantity);
    final unitController = TextEditingController(text: currentUnit);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit $name"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Quantity",
                hintText: "Enter quantity"
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: unitController,
              decoration: InputDecoration(
                labelText: "Unit/Metric",
                hintText: "e.g., kg, g, pcs, liters",
                helperText: "Suggested: ${_metricsService.getMetricsForIngredient(name)}",
                helperStyle: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              final newQuantity = quantityController.text.trim();
              String newUnit = unitController.text.trim().isNotEmpty ? unitController.text.trim() : currentUnit;
              
              // If user didn't enter a unit, use the suggested metric
              if (newUnit == currentUnit && unitController.text.trim().isEmpty) {
                final suggestedMetric = _metricsService.getMetricsForIngredient(name);
                if (suggestedMetric.isNotEmpty) {
                  newUnit = suggestedMetric;
                }
              }
              
              if (newQuantity.isNotEmpty && newUnit.isNotEmpty) {
                final shoppingService = Provider.of<ShoppingListService>(context, listen: false);
                shoppingService.updateItem(name, newQuantity, newUnit);
              }
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _shareShoppingList(List<Map<String, dynamic>> items) {
    if (items.isEmpty) return;

    final itemsText = items
        .map((item) =>
            '• ${item['name']} - ${item['quantity']} ${item['unit']}')
        .join('\n');

    Share.share(
      '🛒 My Shopping List\n\n$itemsText\n\nShared via Aroma',
    );
  }

  double _parseQty(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

  @override
  Widget build(BuildContext context) {
    final pantry = context.watch<PantryState>();
    final shoppingService = context.watch<ShoppingListService>();
    final shoppingItems = shoppingService.items;
    
    // Debug logging
    debugPrint('=== Shopping List Debug ===');
    debugPrint('Total items: ${shoppingItems.length}');
    for (var item in shoppingItems) {
      debugPrint('Item: ${item['name']}, Qty: ${item['quantity']}, Unit: ${item['unit']}, ImageUrl: ${item['imageUrl']}');
    }
    debugPrint('==========================');

    bool needsToBuy(String item, double requiredQty) {
      return pantry.getQty(item) < requiredQty;
    }

        return Scaffold(
          backgroundColor: Colors.white,

          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              "Shopping List",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              if (shoppingItems.isNotEmpty)
                TextButton(
                  onPressed: shoppingService.clearAll,
                  child: const Text(
                    "Clear All",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),

          body: Column(
            children: [
              // Show count header even when empty
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.shopping_cart, color: Colors.orange.shade600),
                    const SizedBox(width: 8),
                    Text(
                      '${shoppingItems.length} items in shopping list',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: shoppingItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_cart_outlined,
                              size: 64,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Your shopping list is empty',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add items from low stock or pantry',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: shoppingItems.length,
                        itemBuilder: (context, index) {
                          final item = shoppingItems[index];

                          final double requiredQty = _parseQty(item['quantity']);
                          
                          // Get appropriate unit for item
                          String unit = item['unit'] ?? '';
                          // If unit is empty or default 'pcs', try to get better metric from service
                          if ((unit.isEmpty || unit == 'pcs') && _metricsLoaded) {
                            final suggestedMetric = _metricsService.getMetricsForIngredient(item['name']);
                            debugPrint('ShoppingList: ${item['name']} -> item unit: "$unit", suggested metric: $suggestedMetric');
                            if (suggestedMetric.isNotEmpty) {
                              unit = suggestedMetric; // Keep the full metric string like "500 g"
                            }
                          } else if (unit.isEmpty && !_metricsLoaded) {
                            unit = 'pcs'; // fallback while loading
                          }
                          
                          debugPrint('ShoppingList: ${item['name']} -> final unit: $unit (loaded: $_metricsLoaded)');

  final bool stillNeeded = needsToBuy(
    item['name'],
    requiredQty,
  );


                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Consumer<PantryState>(
                                  builder: (context, pantryState, child) {
                                    return ItemImageResolver.getImageWidget(
                                      item['name'],
                                      size: 64,
                                      imageUrl: pantryState.getItemImage(item['name']) ?? item['imageUrl'],
                                    );
                                  },
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item['name'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  if (stillNeeded)
                                    const Icon(
                                      Icons.warning_amber_rounded,
                                      color: Colors.orange,
                                      size: 18,
                                    ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${item['category']}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Qty: ${item['quantity']} | Metric: $unit',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Edit button
                                  GestureDetector(
                                    onTap: () => _editItem(
                                      item['name'],
                                      item['quantity'].toString(),
                                      item['unit'],
                                    ),
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
                                  const SizedBox(width: 8),
                                  // Delete button
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    onPressed: () =>
                                        shoppingService.removeItem(item['name']),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),

          floatingActionButton: shoppingItems.isEmpty
              ? null
              : FloatingActionButton.extended(
                  onPressed: () =>
                      _shareShoppingList(shoppingItems),
                  backgroundColor: Colors.orange,
                  icon: const Icon(Icons.share, color: Colors.white),
                  label: const Text(
                    'Share List',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
        );
  }
}