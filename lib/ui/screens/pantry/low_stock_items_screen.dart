import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../state/pantry_state.dart';
import '../../../core/services/auth_service.dart';
import '../../../data/services/shopping_list_service.dart';
import '../../../data/services/ingredient_metrics_service.dart';
import '../../../core/utils/category_engine.dart';
import '../../../core/utils/item_image_resolver.dart';
import '../../../ui/widgets/ingredient_row.dart';
import 'shopping_list_screen.dart';

class LowStockItemsScreen extends StatefulWidget {
  const LowStockItemsScreen({Key? key}) : super(key: key);

  @override
  State<LowStockItemsScreen> createState() => _LowStockItemsScreenState();
}
class _LowStockItemsScreenState extends State<LowStockItemsScreen> {
  final IngredientMetricsService _metricsService = IngredientMetricsService();
  bool _metricsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    await _metricsService.loadMetrics();
    if (mounted) {
      setState(() {
        _metricsLoaded = true;
      });
    }
  }

  // ---------------- EDIT ITEM ----------------
  Future<void> _editItem(String name, double currentQuantity, String currentUnit) async {
    final quantityController = TextEditingController(text: currentQuantity.toString());
    final unitController = TextEditingController(text: currentUnit);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit $name"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const Text("Quantity", style: TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            StatefulBuilder(
              builder: (context, setDialogState) {
                double qty = double.tryParse(quantityController.text) ?? 1.0;
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFF7A4A)),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, color: Color(0xFFFF7A4A)),
                        onPressed: () {
                          if (qty > 0.5) {
                            qty -= 0.5;
                            quantityController.text = qty.toStringAsFixed(1);
                            setDialogState(() {});
                          }
                        },
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            qty.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: Color(0xFFFF7A4A)),
                        onPressed: () {
                          qty += 0.5;
                          quantityController.text = qty.toStringAsFixed(1);
                          setDialogState(() {});
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: unitController,
              decoration: InputDecoration(
                labelText: "Unit/Metric",
                hintText: "e.g., kg, g, pcs, liters",
                helperText: "Suggested: ${_metricsService.getMetricsForIngredient(name)}",
                helperStyle: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              )
            )
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
              
              if (newUnit == currentUnit && unitController.text.trim().isEmpty) {
                final suggestedMetric = _metricsService.getMetricsForIngredient(name);
                if (suggestedMetric.isNotEmpty) {
                  newUnit = suggestedMetric;
                }
              }
              
              if (newQuantity.isNotEmpty && newUnit.isNotEmpty) {
                final shoppingService = Provider.of<ShoppingListService>(context, listen: false);
                shoppingService.addItem(
                  name: name,
                  quantity: double.tryParse(newQuantity) ?? 1.0,
                  unit: newUnit,
                  category: CategoryEngine.getCategory(name),
                );
              }
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pantryState = context.watch<PantryState>();
    final lowStockItems = pantryState.items.where((item) => pantryState.isLowStock(item.name)).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Low Stock Items",
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: lowStockItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "No low stock items",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Items with quantity ≤ 3 will appear here",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: lowStockItems.length,
              itemBuilder: (context, index) {
                final item = lowStockItems[index];
                final name = item.name;
                final qty = item.quantity;
                final unit = item.unit;
                
                return IngredientRow(
                  emoji: ItemImageResolver.getEmojiForIngredient(name),
                  name: name,
                  matchPercent: 100,
                  quantity: qty,
                  onRemove: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Dismiss Item"),
                        content: Text("Remove $name from low stock list? (Item will remain in pantry)"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              pantryState.hideFromLowStock(name);
                              
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("$name dismissed from low stock"),
                                    backgroundColor: Colors.orange,
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              }
                            },
                            child: const Text("Remove"),
                          ),
                        ],
                      ),
                    );
                  },
                  onEdit: () => _editItem(name, qty, unit),
                  useImageService: true, 
                  imageUrl: item.imageUrl,
                );
              },
            ),
    );
  }
}