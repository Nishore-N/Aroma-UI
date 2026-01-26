import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../state/pantry_state.dart';
import '../../../core/utils/category_engine.dart';
import '../../../core/utils/item_image_resolver.dart';

const Color kAccent = Color(0xFFFF7A4A);

class CategoryItemsScreen extends StatefulWidget {
  final String category;
  final List<Map<String, dynamic>> allItems;

  const CategoryItemsScreen({
    super.key,
    required this.category,
    required this.allItems,
  });

  @override
  State<CategoryItemsScreen> createState() => _CategoryItemsScreenState();
}

class _CategoryItemsScreenState extends State<CategoryItemsScreen> {
  String search = "";
  late String selectedCategory;

  final List<String> categories = const [
    "Fruits & Vegetables",
    "Dairy & Alternatives",
    "Eggs, Meat & Fish",
    "Nuts & Dry Fruits",
    "Spices & Masalas",
    "Grains & Staples",
    "Ready-to-Eat",
    "Others",
  ];

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.category;
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = widget.allItems.where((item) {
      final itemCategory = CategoryEngine.getCategory(item['name']);
      final matchesCategory = itemCategory == selectedCategory;
      final matchesSearch =
          item['name'].toLowerCase().contains(search.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          selectedCategory,
          style: const TextStyle(color: Colors.black),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔹 CATEGORY CHIPS
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final cat = categories[i];
                  final selected = cat == selectedCategory;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedCategory = cat;
                        search = "";
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: kAccent),
                        color: selected
                            ? kAccent.withOpacity(0.15)
                            : Colors.white,
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: selected ? kAccent : Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // 🔍 SEARCH BAR
            TextField(
              onChanged: (v) => setState(() => search = v),
              decoration: InputDecoration(
                hintText: "Search Ingredients",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 📋 ITEM LIST
            Expanded(
              child: filteredItems.isEmpty
                  ? const Center(
                      child: Text(
                        "No items found",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredItems.length,
                      itemBuilder: (_, index) {
                        return _itemCard(filteredItems[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ CARD WITH GENERATED IMAGE
  Widget _itemCard(Map<String, dynamic> item) {
    final category = CategoryEngine.getCategory(item['name']);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // 🖼 GENERATED IMAGE
          ClipOval(
            child: Consumer<PantryState>(
              builder: (context, pantryState, child) {
                return ItemImageResolver.getImageWidget(
                  item['name'],
                  size: 48,
                  imageUrl: item['imageUrl']?.isNotEmpty == true 
                      ? item['imageUrl'] as String 
                      : pantryState.getItemImage(item['name']),
                );
              },
            ),
          ),

          const SizedBox(width: 12),

          // 📝 TEXT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'],
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "in $category | Avl Qty : ${item['quantity']}",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  item['unit'] ?? 'pcs',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
