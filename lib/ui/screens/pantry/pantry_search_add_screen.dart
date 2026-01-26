import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../state/pantry_state.dart';
import '../../../core/utils/item_image_resolver.dart';
import 'pantry_home_screen.dart';
import '../../../data/services/shopping_list_service.dart';

const Color kAccent = Color(0xFFFF7A4A);
const Color kBgLight = Color(0xFFFFF1EB);
const Color kAddBg = Color(0xFFFFEFE9);
const Color kAddedBg = Color(0xFFE8F6ED);

class PantrySearchAddScreen extends StatefulWidget {
  const PantrySearchAddScreen({super.key});

  @override
  State<PantrySearchAddScreen> createState() =>
      _PantrySearchAddScreenState();
}

class _PantrySearchAddScreenState extends State<PantrySearchAddScreen> {
  Set<String> pantryNames = {};
  int addedCount = 0;
  bool loading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  /// Stores quantity & unit for UI (KEY = normalized name)
  Map<String, Map<String, dynamic>> pantryItemDetails = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncFromPantryState(); // 🔥 always re-sync when screen appears
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ---------------- NAME NORMALIZATION ----------------
  String normalizeName(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'^w\s+'), '') // remove "W "
        .replaceAll('.', '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  final List<Map<String, String>> allIngredients = [
    {"name": "Onion", "category": "Fruits & Vegetables"},
    {"name": "Tomato", "category": "Fruits & Vegetables"},
    {"name": "Banana", "category": "Fruits & Vegetables"},
    {"name": "Apple", "category": "Fruits & Vegetables"},
    {"name": "Potato", "category": "Fruits & Vegetables"},
    {"name": "Aubergine", "category": "Fruits & Vegetables"},
    {"name": "Cherry Tomatoes", "category": "Fruits & Vegetables"},
    {"name": "Milk", "category": "Dairy & Alternatives"},
    {"name": "Cottage Cheese", "category": "Dairy & Alternatives"},
    {"name": "Rice", "category": "Pantry staples"},
    {"name": "Sugar", "category": "Pantry staples"},
    {"name": "Salt", "category": "Pantry staples"},
    {"name": "Oil", "category": "Pantry staples"},
  ];

  // ---------------- SYNC FROM PANTRY ----------------
  void _syncFromPantryState() {
    final pantryState = context.read<PantryState>();

    pantryNames.clear();
    pantryItemDetails.clear();

    for (final item in pantryState.items) {
      final key = normalizeName(item.name);

      pantryNames.add(key);
      pantryItemDetails[key] = {
        "quantity": item.quantity,
        "unit": item.unit,
      };
    }

    setState(() {
      addedCount = pantryNames.length;
      loading = false;
    });
  }

  bool _isAdded(String name) =>
      pantryNames.contains(normalizeName(name));

  // ===================== BOTTOM SHEET =====================
  void _openQuantitySheet(String displayName) {
    final key = normalizeName(displayName);

    final qtyController = TextEditingController(
      text: pantryItemDetails[key]?['quantity']?.toString() ?? '',
    );

    String selectedUnit =
        pantryItemDetails[key]?['unit'] ?? "pcs";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ItemImageResolver.getImageWidget(
                          displayName,
                          size: 44,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        displayName,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  const Text("Quantity",
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),

                  TextField(
                    controller: qtyController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "Quantity",
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        if (qtyController.text.isEmpty) return;

                        final quantity =
                            double.tryParse(qtyController.text) ?? 0;

                        final pantryState =
                            context.read<PantryState>();
                        final shoppingService =
                            context.read<ShoppingListService>();

                        // 1️⃣ SAVE TO PANTRY (normalized key)
                        pantryState.setItem(
                          key,
                          quantity,
                          selectedUnit,
                        );

                        // 2️⃣ SAVE TO SHOPPING LIST (all quantities)
                        shoppingService.addItem(
                          name: key,
                          quantity: quantity,
                          unit: selectedUnit,
                          category: "Pantry",
                          imageUrl: null, // No imageUrl available in this screen
                        );

                        setState(() {
                          pantryNames.add(key);
                          pantryItemDetails[key] = {
                            "quantity": quantity,
                            "unit": selectedUnit,
                          };
                          addedCount = pantryNames.length;
                        });

                        Navigator.pop(context);
                      },
                      child: const Text(
                        "Save & add another",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ===================== UI =====================
  // Filter ingredients based on search query
  List<Map<String, String>> _filterIngredients(List<Map<String, String>> allItems, String query) {
    if (query.isEmpty) return allItems;
    
    return allItems.where((item) {
      return item['name']!.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final pantry = context.watch<PantryState>();

    // 🔥 MERGE STATIC + PANTRY ITEMS
    final Map<String, Map<String, String>> mergedIngredients = {
      for (final i in allIngredients)
        normalizeName(i['name']!): i,
    };

    for (final item in pantry.items) {
      final key = normalizeName(item.name);
      mergedIngredients.putIfAbsent(
        key,
        () => ({
          'name': item.name,
          'category': 'Scanned Items',
        }),
      );
    }

    final allIngredientList = mergedIngredients.values.toList();
    final filteredIngredients = _filterIngredients(allIngredientList, _searchQuery);

    return Scaffold(
      backgroundColor: Colors.white,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header with search
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Close button
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.close, size: 20),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Search bar
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search Ingredients',
                            hintStyle: TextStyle(color: Colors.grey[500]),
                            prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Added bar
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16),
                  color: kBgLight,
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Item Added: $addedCount",
                          style: const TextStyle(
                              fontWeight: FontWeight.w600)),
                      OutlinedButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const PantryHomeScreen()),
                            (_) => false,
                          );
                        },
                        child: const Text("Finish Adding"),
                      )
                    ],
                  ),
                ),

                // List
                Expanded(
                  child: filteredIngredients.isEmpty
                      ? Center(
                          child: Text(
                            'No items found',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 16,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredIngredients.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final item = filteredIngredients[i];
                            final name = item['name']!;
                            final added = _isAdded(name);

                      return Row(
                        children: [
                          ItemImageResolver.getImageWidget(
                            name,
                            size: 48,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _openQuantitySheet(name),
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color:
                                    added ? kAddedBg : kAddBg,
                                borderRadius:
                                    BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    added
                                        ? Icons.check
                                        : Icons.add,
                                    size: 16,
                                    color: added
                                        ? Colors.green
                                        : kAccent,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    added ? "Added" : "Add",
                                    style: TextStyle(
                                      color: added
                                          ? Colors.green
                                          : kAccent,
                                      fontWeight:
                                          FontWeight.w600,
                                    ),
                                  )
                                ],
                              ),
                            ),
                          )
                        ],
                      );
                    },
                  ),
                )
              ],
            ),
    );
  }
}
