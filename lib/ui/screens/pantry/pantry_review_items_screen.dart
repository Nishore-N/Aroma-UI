import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';

import '../../../core/services/auth_service.dart';
import '../../../data/services/pantry_add_service.dart';

import '../../../data/models/ingredient_model.dart';
import '../../../widgets/primary_button.dart';
import '../../../state/pantry_state.dart';


class PantryReviewItemsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> items;

  const PantryReviewItemsScreen({
    super.key,
    required this.items,
  });

  @override
  State<PantryReviewItemsScreen> createState() =>
      _PantryReviewItemsScreenState();
}

class _PantryReviewItemsScreenState extends State<PantryReviewItemsScreen> {
  late List<IngredientModel> _ingredients;
  final Map<String, int> _quantities = {};
  final Map<String, TextEditingController> _priceControllers = {};

  @override
  void initState() {
    super.initState();
    _initializeIngredients();
  }

  @override
  void dispose() {
    for (var controller in _priceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // 🔥 NORMALIZE SCANNED ITEM NAMES
  String _normalizeScanName(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'^w\s+'), '') // remove "W "
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  void _initializeIngredients() {
    _ingredients = widget.items.map((item) {
      debugPrint("🧪 REVIEW ITEM RAW: $item"); // 🔥 ADD THIS
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
      final price = (item['price'] as num?)?.toDouble() ?? 0.0;

      _quantities[id] = quantity;
      _priceControllers[id] =
          TextEditingController(text: price.toStringAsFixed(2));

      return IngredientModel(
        id: id,
        name: (item['item'] ?? item['name'] ?? 'Unknown Item').toString(),
        quantity: quantity.toDouble(),
        unit: item['unit']?.toString() ?? 'pcs',
        price: price,
      );
    }).toList();
  }

  void _updateQuantity(String id, int newQuantity) {
    if (newQuantity > 0) {
      setState(() {
        _quantities[id] = newQuantity;
      });
    }
  }

  void _removeItem(String id) {
    setState(() {
      _ingredients.removeWhere((item) => item.id == id);
      _quantities.remove(id);
      _priceControllers.remove(id)?.dispose();
    });
  }

  List<Map<String, dynamic>> _getUpdatedItems() {
    return _ingredients.map((ingredient) {
      final price = double.tryParse(
            _priceControllers[ingredient.id]?.text ?? '0',
          ) ??
          0.0;

      return {
        'name': ingredient.name,
        'quantity': _quantities[ingredient.id] ?? 1,
        'unit': ingredient.unit,
        'price': price,
      };
    }).toList();
  }

  // 🔥 CORE FIX: SAVE TO PANTRY STATE
  Future<void> _addItemsToPantry() async {
  final pantryState = context.read<PantryState>();
  final authService = context.read<AuthService>();
  final items = _getUpdatedItems();

  debugPrint("🧪 ADD TO PANTRY CLICKED: ${items.length} items");

  // Show loading indicator
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(
      child: CircularProgressIndicator(),
    ),
  );

  try {
    for (final item in items) {
      final rawName = item['name']?.toString() ?? '';

      final normalizedName = rawName
          .toLowerCase()
          .replaceAll(RegExp(r'^w\s+'), '') // removes "W APPLE"
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      final qty = (item['quantity'] as num).toDouble();
      final unit = item['unit']?.toString() ?? 'pcs';

      debugPrint("➡ Saving local: $normalizedName | $qty $unit");

      pantryState.setItem(normalizedName, qty, unit);
    }

    // Call remote API
    final String? userId = authService.user?.mobile_no;
    final pantryService = PantryAddService();
    final serverResponse = await pantryService.addIndividualPantryItems(items, userId: userId);
    
    debugPrint("✅ Server addition result: $serverResponse");
    
    // Verify using IDs if present in response
    if (serverResponse['status'] == true && serverResponse['added_items'] != null) {
      final addedItems = serverResponse['added_items'] as List;
      debugPrint("🔍 Verified ${addedItems.length} items added with IDs");
    }

    if (mounted) {
      Navigator.pop(context); // Close loading dialog
      Navigator.pop(context, items);
    }
  } catch (e) {
    debugPrint("❌ Error adding to pantry: $e");
    if (mounted) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add items to pantry: $e")),
      );
    }
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Items'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: _ingredients.isEmpty
                ? _buildEmptyState()
                : _buildIngredientList(),
          ),
          if (_ingredients.isNotEmpty) _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_basket_outlined,
              size: 72, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'No items found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text(
            'We couldn\'t find any items in your receipt.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _ingredients.length,
      itemBuilder: (context, index) {
        final ingredient = _ingredients[index];
        final quantity = _quantities[ingredient.id] ?? 1;
        final priceController = _priceControllers[ingredient.id]!;

        return Dismissible(
          key: Key(ingredient.id ?? ''),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) => _removeItem(ingredient.id ?? ''),
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ingredient.name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () =>
                            _updateQuantity(ingredient.id ?? '', quantity - 1),
                      ),
                      Text(quantity.toString()),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () =>
                            _updateQuantity(ingredient.id ?? '', quantity + 1),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: priceController,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Price',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        child: PrimaryButton(
          label: 'Add to Pantry',
          onPressed: _addItemsToPantry, // 🔥 UPDATED
        ),
      ),
    );
  }
}
