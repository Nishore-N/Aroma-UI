import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../state/pantry_state.dart';
import '../../../data/services/shopping_list_service.dart';
import '../../../data/services/ingredient_metrics_service.dart';
import '../../../data/services/pantry_list_service.dart';
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
  final PantryListService _pantryListService = PantryListService();
  bool _metricsLoaded = false;
  List<Map<String, dynamic>> _remotePantryItems = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
    _loadRemotePantryItems();
  }

  Future<void> _loadRemotePantryItems() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final pantryItems = await _pantryListService.fetchPantryItems();
      setState(() {
        _remotePantryItems = pantryItems;
        _isLoading = false;
      });
      print('📦 LowStockScreen: Loaded ${pantryItems.length} remote pantry items');
    } catch (e) {
      print('❌ LowStockScreen: Error loading remote pantry items: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Get pantry items from remote server (same as home screen)
  List<Map<String, dynamic>> get pantryItems {
    return _remotePantryItems.map((item) => {
      'name': item['name']?.toString() ?? '',
      'quantity': (item['quantity'] as num?)?.toDouble() ?? 1.0,
      'unit': item['unit']?.toString() ?? 'pcs',
      'imageUrl': '', // Server doesn't provide imageUrl in list response
      'price': (item['price'] as num?)?.toDouble() ?? 0.0,
      'source': item['source']?.toString() ?? 'manual',
      '_id': item['_id']?.toString() ?? '',
    }).toList();
  }

  Future<void> _loadMetrics() async {
    await _metricsService.loadMetrics();
    setState(() {
      _metricsLoaded = true;
    });
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                "Loading low stock items...",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Calculate low stock items from remote data (same logic as home screen)
    final lowStockItems = pantryItems.where((item) {
      final qty = item['quantity'] is num ? (item['quantity'] as num).toDouble() : 0;
      return qty > 0 && qty <= 3;
    }).toList();

    // Debug logging
    debugPrint('=== Low Stock Debug ===');
    debugPrint('Total remote pantry items: ${pantryItems.length}');
    debugPrint('Low stock items count: ${lowStockItems.length}');
    for (var item in lowStockItems) {
      debugPrint('Low stock item: ${item['name']} -> quantity: ${item['quantity']}');
    }
    debugPrint('====================');

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
                Icon(
                  Icons.inventory_2_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  "No low stock items",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
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
              final name = item['name'].toString();
              final qty = item['quantity'] as double;
              final unit = item['unit'].toString();
              
              debugPrint('LowStock: $name -> quantity: $qty, unit: $unit');

              return IngredientRow(
                emoji: ItemImageResolver.getEmojiForIngredient(name),
                name: name,
                matchPercent: 100,
                quantity: qty.toInt(),
                onRemove: () {
                  // Show confirmation dialog before removing
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Remove Item"),
                      content: Text("Are you sure you want to remove $name from low stock items?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () {
                            // Remove from pantry items
                            setState(() {
                              _remotePantryItems.removeWhere((item) => item['name'] == name);
                            });
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("$name removed from pantry"),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: const Text("Remove"),
                        ),
                      ],
                    ),
                  );
                },
                onEdit: () => _editItem(name, qty, unit),
                useImageService: false, // Low stock items don't have image URLs
                imageUrl: null,
              );
            },
          ),
    );
  }
}