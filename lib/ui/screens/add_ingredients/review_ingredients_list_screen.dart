import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/ingredient_card.dart';
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
  final Map<String, double> _quantityMap = {};
  final Map<String, String> _unitMap = {}; // Store units
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
      final ing = result["ingredients"] ?? [];
      debugPrint("🎯 [ReviewIngredientsListScreen] Processing ${ing.length} ingredients");

      _ingredients = ing.map<IngredientModel>((item) {
        final id = DateTime.now().microsecondsSinceEpoch.toString();

        _priceMap[id] =
            double.tryParse(item["price"]?.toString() ?? "0") ?? 0.0;
        _quantityMap[id] =
            double.tryParse(item["qty"]?.toString() ?? "1.0") ?? 1.0;
        
        // Handle apx_unit_value and apx_unit from backend response
        final apxValue = item["apx_unit_value"];
        final apxUnit = item["apx_unit"];
        String unitStr = "pcs"; // Default
        
        if (apxValue != null && apxUnit != null) {
           _unitMap[id] = "$apxValue $apxUnit"; // Pre-format unit string like "454 gm" if both present
        } else if (apxUnit != null) {
           _unitMap[id] = apxUnit.toString();
        } else {
           _unitMap[id] = "pcs";
        }

        _imageMap[id] = item["image_url"]?.toString() ?? ""; // Use image_url from new API
        debugPrint("🎯 [ReviewIngredientsListScreen] Image mapping for ${item["name"]}: ${_imageMap[id]}");

        // Use confidence from backend if available, convert to percentage
        final confidence = double.tryParse(item["confidence"]?.toString() ?? "1.0") ?? 1.0;
        final matchPercent = (confidence * 100).toInt();

        return IngredientModel(
          id: id,
          emoji: ItemImageResolver.getEmojiForIngredient(item["name"]?.toString() ?? ""),
          name: item["name"]?.toString() ?? "",
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
    final quantityController = TextEditingController(text: "1.0");

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
            const SizedBox(height: 16),
            const Text("Quantity", style: TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            StatefulBuilder(
              builder: (context, setDialogState) {
                double qty = double.tryParse(quantityController.text) ?? 1.0;
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, color: AppColors.primary),
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
                        icon: const Icon(Icons.add, color: AppColors.primary),
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
                      double.tryParse(quantityController.text) ?? 1.0;
                  _unitMap[id] = "pcs"; // Default unit for added item
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
    
    final quantityController = TextEditingController(text: currentQuantity.toStringAsFixed(1));

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit ${item.name}"),
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
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, color: AppColors.primary),
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
                        icon: const Icon(Icons.add, color: AppColors.primary),
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              final newQuantity = double.tryParse(quantityController.text) ?? currentQuantity;
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
      _unitMap.remove(id);
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


      // ---------- BODY ----------
      body: Column(
        children: [
          // Header moved to body for precise spacing control
          Container(
            color: Colors.white,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 48, 18, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () {
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
                      const SizedBox(height: 12),
                      const Text(
                        'Review Ingredients',
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 28,
                            color: Colors.black),
                      ),
                    ],
                  ),
                ),
                const Divider(
                  height: 1, 
                  thickness: 1, 
                  color: Color(0xFFE5E5E5)
                ),
              ],
            ),
          ),
          
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
                if (_ingredients.isEmpty) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: const Text(
                        "No Ingredients",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      content: const Text(
                        "Please select ingredients to proceed",
                        style: TextStyle(fontSize: 16),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            "OK",
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                  return;
                }

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
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: _ingredients.length,
      itemBuilder: (context, index) {
        final item = _ingredients[index];
        final price = _priceMap[item.id] ?? 0.0;
        final double qty = _quantityMap[item.id] ?? 1.0;
        final String unitString = _unitMap[item.id] ?? "pcs";
        
        // Logic: 
        // 1. Quantity field: Display pure qty (e.g. "1.0").
        // 2. Approx field: Display apx_unit_value + apx_unit if available (e.g. "454 gm").
        
        String quantityStr = '${qty.toStringAsFixed(qty.truncateToDouble() == qty ? 0 : 1)}';
        String? approxStr;

        if (unitString.contains(RegExp(r'\d'))) {
            // unitString contains digits, meaning it has apx info
            approxStr = unitString;
        } 
        
        return Column(
          children: [
            IngredientCard(
              emoji: item.emoji,
              name: item.name,
              quantity: quantityStr, 
              approxQuantity: approxStr, 
              match: '${item.match}%', 
              onRemove: () => _removeIngredient(index),
              onEdit: () => _showEditIngredientDialog(index), 
              imageUrl: _imageMap[item.id], 
            ),
            const Divider(
              height: 1, 
              color: Color(0xFFF0F0F0), 
              thickness: 1,
            ),
          ],
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