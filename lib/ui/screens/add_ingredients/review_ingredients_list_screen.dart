import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/ingredient_row.dart';
import '../preferences/cooking_preference_screen.dart';
import '../../../data/models/ingredient_model.dart';
import '../../../data/services/ingredient_image_service.dart';
import '../../../data/services/ingredient_metrics_service.dart';
import '../../../core/utils/item_image_resolver.dart';

class ReviewIngredientsListScreen extends StatefulWidget {
  final dynamic scanResult;

  const ReviewIngredientsListScreen({
    super.key,
    required this.scanResult,
  });

  @override
  State<ReviewIngredientsListScreen> createState() =>
      _ReviewIngredientsListScreenState();
}

class _ReviewIngredientsListScreenState
    extends State<ReviewIngredientsListScreen> {
  List<IngredientModel> _ingredients = [];

  /// 👉 Store price, quantity & metrics separately (clean approach)
  final Map<String, double> _priceMap = {};
  final Map<String, int> _quantityMap = {};
  final Map<String, String> _imageMap = {}; // Store image URLs
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final screenStartTime = DateTime.now();
    debugPrint("🎯 [ReviewIngredientsListScreen] Screen init started at: ${screenStartTime.millisecondsSinceEpoch}");

    // Skip metrics loading for development speed (same as pantry review)
    _fetchIngredients();

    final screenEndTime = DateTime.now();
    debugPrint("🎯 [ReviewIngredientsListScreen] Screen init completed at: ${screenEndTime.millisecondsSinceEpoch}");
    debugPrint("⏱️ [ReviewIngredientsListScreen] Init time: ${screenEndTime.difference(screenStartTime).inMilliseconds}ms");
  }

  Future<void> _loadMetricsAndFetchIngredients() async {
    _fetchIngredients();
  }

  // ---------------- Fetch Ingredients from Scan ----------------
  Future<void> _fetchIngredients() async {
    final fetchStartTime = DateTime.now();
    debugPrint("🎯 [ReviewIngredientsListScreen] Starting ingredient fetch at: ${fetchStartTime.millisecondsSinceEpoch}");

    try {
      final result = widget.scanResult;
      final ing = result["ingredients_with_quantity"] ?? [];
      debugPrint("🎯 [ReviewIngredientsListScreen] Processing ${ing.length} ingredients");

      _ingredients = ing.map<IngredientModel>((item) {
        final id = DateTime.now().microsecondsSinceEpoch.toString();

        _priceMap[id] =
            double.tryParse(item["price"]?.toString() ?? "0") ?? 0.0;
        _quantityMap[id] =
            int.tryParse(item["quantity"]?.toString() ?? "1") ?? 1;
        _imageMap[id] = item["imageURL"]?.toString() ?? item["image_url"]?.toString() ?? ""; // Store image URL
        debugPrint("🎯 [ReviewIngredientsListScreen] Image mapping for ${item["item"]}: ${_imageMap[id]}");

        // Use match percentage from backend if available, default to 100
        final matchPercent = int.tryParse(item["match"]?.toString() ?? item["match%"]?.toString() ?? "100") ?? 100;

        return IngredientModel(
          id: id,
          emoji: ItemImageResolver.getEmojiForIngredient(item["item"]?.toString() ?? ""),
          name: item["item"]?.toString() ?? "",
          match: matchPercent,
        );
      }).toList();

      final fetchEndTime = DateTime.now();
      debugPrint("🎯 [ReviewIngredientsListScreen] Ingredient fetch completed at: ${fetchEndTime.millisecondsSinceEpoch}");
      debugPrint("⏱️ [ReviewIngredientsListScreen] Fetch time: ${fetchEndTime.difference(fetchStartTime).inMilliseconds}ms");

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint("❌ [ReviewIngredientsListScreen] Fetch failed: $e");
      setState(() {
        _error = "Failed: $e";
        _isLoading = false;
      });
    }
  }

  // =====================================================
  // ADD INGREDIENT (NAME + METRIC + QUANTITY)
  // =====================================================
  Future<void> _showAddIngredientDialog() async {
    final nameController = TextEditingController();
    final metricController = TextEditingController();
    final quantityController = TextEditingController(text: "1");

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Ingredient"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration:
                  const InputDecoration(labelText: "Ingredient name"),
            ),
            TextField(
              controller: metricController,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(labelText: "Metric"),
            ),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Quantity"),
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
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                final id =
                    DateTime.now().microsecondsSinceEpoch.toString();

                setState(() {
                  _ingredients.add(
                    IngredientModel(
                      id: id,
                      emoji: ItemImageResolver.getEmojiForIngredient(name),
                      name: name,
                      match: 100,
                    ),
                  );
                  _priceMap[id] = 0.0; // Price not used in home screen
                  _quantityMap[id] =
                      int.tryParse(quantityController.text) ?? 1;
                });
              }
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  // ---------------- Edit Ingredient ----------------
  Future<void> _showEditIngredientDialog(int index) async {
    final item = _ingredients[index];
    final currentQuantity = _quantityMap[item.id] ?? 1;
    
    final quantityController = TextEditingController(text: currentQuantity.toString());

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit ${item.name}"),
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              final newQuantity = int.tryParse(quantityController.text) ?? currentQuantity;
              final itemId = item.id;
              
              if (itemId?.isNotEmpty == true) {
                setState(() {
                  _quantityMap[itemId!] = newQuantity;
                });
              }
              
              Navigator.pop(context);
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }
  // ---------------- Remove Ingredient ----------------
  void _removeIngredient(int index) {
    final id = _ingredients[index].id;
    setState(() {
      _priceMap.remove(id);
      _quantityMap.remove(id);
      _imageMap.remove(id); // Remove image URL
      _ingredients.removeAt(index);
    });
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),

      // ---------- HEADER ----------
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(160),
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(18, 40, 18, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      // Reset parent screen state before popping
                      Navigator.pop(context, 'reset_state');
                    },
                    child: _circleIcon(Icons.arrow_back),
                  ),
                  GestureDetector(
                    onTap: _showAddIngredientDialog,
                    child: _addMoreBtn(),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Text(
                'Review Ingredients',
                style:
                    TextStyle(fontWeight: FontWeight.w900, fontSize: 28),
              ),
            ],
          ),
        ),
      ),

      // ---------- BODY ----------
      body: Column(
        children: [
          Expanded(child: _buildBody()),

          // ---------- PROCEED BUTTON ----------
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 12,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: GestureDetector(
              onTap: () async {
                // Continue with normal flow - no MongoDB storage for speed
                final ingredientsPayload = _ingredients.map((e) {
                  return {
                    "item": e.name,
                    "price": _priceMap[e.id] ?? 0.0,
                    "quantity": _quantityMap[e.id] ?? 1,
                  };
                }).toList();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CookingPreferenceScreen(
                      ingredients: ingredientsPayload,
                    ),
                  ),
                );
              },
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Center(
                  child: Text(
                    'Proceed',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 17,
                        color: Colors.black),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- LIST UI ----------
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (_ingredients.isEmpty) {
      return const Center(child: Text('No ingredients found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      itemCount: _ingredients.length,
      itemBuilder: (context, index) {
        final item = _ingredients[index];
        final price = _priceMap[item.id] ?? 0.0;
        final qty = _quantityMap[item.id] ?? 1;
        
        return IngredientRow(
          emoji: item.emoji,
          name: item.name,
          matchPercent: item.match,
          quantity: qty,
          onRemove: () => _removeIngredient(index),
          onEdit: () => _showEditIngredientDialog(index),
          useImageService: true,
          imageUrl: _imageMap[item.id], // Pass image URL
        );
      },
    );
  }

  Widget _circleIcon(IconData icon) {
    return Container(
      height: 42,
      width: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black.withOpacity(0.15)),
      ),
      child: Icon(icon, size: 20),
    );
  }

  Widget _addMoreBtn() {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFFFFF0E9),
        border:
            const Border.fromBorderSide(BorderSide(color: Color(0xFFFF6A45))),
      ),
      child: const Center(
        child: Text(
          'Add more',
          style: TextStyle(
              color: Color(0xFFFF6A45),
              fontWeight: FontWeight.w600,
              fontSize: 14.5),
        ),
      ),
    );
  }
}