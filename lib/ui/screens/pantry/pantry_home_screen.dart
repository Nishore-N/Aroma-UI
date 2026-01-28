import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../state/pantry_state.dart';
import '../../../core/services/auth_service.dart';
import '../../../data/services/shopping_list_service.dart';
import '../../../data/services/pantry_list_service.dart';
import '../../../data/services/pantry_image_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/category_engine.dart';
import '../../../core/utils/item_image_resolver.dart';
import 'pantry_empty_screen.dart';
import 'low_stock_items_screen.dart';
import 'shopping_list_screen.dart';
import 'category_items_screen.dart';
import 'pantry_item_details_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../home/home_screen.dart';
import 'pantry_search_add_screen.dart';
import '../add_ingredients/ingredient_entry_screen.dart';
import '../../../core/enums/scan_mode.dart';


const Color kAccent = Color(0xFFFF7A4A);
const Color kLightAccent = Color(0xFFFFE8E0);

class PantryHomeScreen extends StatefulWidget {
  const PantryHomeScreen({super.key});

  @override
  State<PantryHomeScreen> createState() => _PantryHomeScreenState();
}

class _PantryHomeScreenState extends State<PantryHomeScreen> with WidgetsBindingObserver {
  final PantryListService _pantryListService = PantryListService();
  final PantryImageService _imageService = PantryImageService();
  List<Map<String, dynamic>> _remotePantryItems = [];
  bool _isLoading = false;
  
  // Selection Mode State
  bool _isSelectionMode = false;
  final Set<String> _selectedItems = {};

  void _toggleSelectionMode(bool value) {
    setState(() {
      _isSelectionMode = value;
      if (!value) {
        _selectedItems.clear();
      }
    });
  }

  void _toggleItemSelection(String itemName) {
    setState(() {
      if (_selectedItems.contains(itemName)) {
        _selectedItems.remove(itemName);
        if (_selectedItems.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedItems.add(itemName);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeServices();
    _loadRemotePantryItems();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh pantry items when app resumes (after adding items)
      _loadRemotePantryItems();
    }
  }

  Future<void> _initializeServices() async {
    // Basic service initialization if needed
  }

  Future<void> _loadRemotePantryItems() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final String? userId = authService.user?.mobile_no;
      
      final pantryItems = await _pantryListService.fetchPantryItems(userId: userId);
      setState(() {
        _remotePantryItems = pantryItems;
        _isLoading = false;
      });
      print('📦 Loaded ${pantryItems.length} remote pantry items: ${pantryItems.map((item) => item['name']).toList()}');
      
      // Trigger image generation for missing items
      _generateMissingImages(pantryItems);
    } catch (e) {
      print('❌ Error loading remote pantry items: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _generateMissingImages(List<Map<String, dynamic>> items) async {
    final pantryState = Provider.of<PantryState>(context, listen: false);
    final List<String> itemNames = items.map((e) => e['name']?.toString() ?? '').where((name) => name.isNotEmpty).toList();
    
    // Check if we need to generate images
    final currentCache = await _imageService.getCachedImages();
    final missing = itemNames.where((name) => !currentCache.containsKey(name)).toList();
    
    if (missing.isNotEmpty) {
      debugPrint('🎨 [PantryHome] Found ${missing.length} items missing images. Starting sequential generation...');
      
      // Generate images one by one sequentially
      int count = 0;
      for (final name in missing) {
        count++;
        debugPrint('🖼️ [PantryHome] Generating image $count/${missing.length} for: $name');
        
        final url = await _imageService.generateItemImage(name);
        if (url != null) {
          await pantryState.updateItemImage(name, url);
          debugPrint('✅ [PantryHome] Completed image generation for: $name ($count/${missing.length})');
        } else {
          debugPrint('⚠️ [PantryHome] Failed to generate image for: $name');
        }
      }
      
      debugPrint('🎉 [PantryHome] All ${missing.length} ingredient images generated sequentially');
    }
  }

  Future<String?> _getPhoneNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_phone');
  }

  // Get pantry items from remote server
  List<Map<String, dynamic>> get pantryItems {
    final pantryState = Provider.of<PantryState>(context, listen: false);
    return _remotePantryItems.map((item) {
      final name = item['name']?.toString() ?? '';
      return {
        'name': name,
        'quantity': (item['quantity'] as num?)?.toDouble() ?? 1.0,
        'unit': item['unit']?.toString() ?? 'pcs',
        'imageUrl': pantryState.getItemImage(name) ?? '', 
        'price': (item['price'] as num?)?.toDouble() ?? 0.0,
        'source': item['source']?.toString() ?? 'manual',
        '_id': item['_id']?.toString() ?? '',
      };
    }).toList();
  }

  // Get low stock item count
  int get lowStockItemCount {
    return pantryItems.where((item) {
      final qty = item['quantity'] is num ? (item['quantity'] as num).toDouble() : 0;
      return qty > 0 && qty <= 3;
    }).length;
  }

  // ---------- CATEGORY ----------
  Map<String, List<Map<String, dynamic>>> _getGroupedItems(List<Map<String, dynamic>> items) {
    final Map<String, List<Map<String, dynamic>>> map = {};
    for (final item in items) {
      final category = CategoryEngine.getCategory(item['name']);
      map.putIfAbsent(category, () => []);
      map[category]!.add(item);
    }
    return map;
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
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const HomeScreen(phoneNumber: ''),
                ),
                (route) => false,
              );
            },
          ),
          title: const Text(
            "Pantry",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                "Loading pantry items...",
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

    if (pantryItems.isEmpty) {
      return const PantryEmptyScreen();
    }

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close, color: Colors.black),
                onPressed: () => _toggleSelectionMode(false),
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
        title: Text(
          _isSelectionMode ? "${_selectedItems.length} Selected" : "Pantry",
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _showDeleteSelectedConfirmation,
            )
          else if (pantryItems.isNotEmpty)
            TextButton.icon(
              onPressed: _showClearAllConfirmation,
              icon: const Icon(Icons.clear_all, color: Colors.red, size: 20),
              label: const Text(
                'Clear All',
                style: TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: Size(0, 40),
              ),
            ),
        ],
      ),

      body: Consumer<PantryState>(
        builder: (context, pantryState, child) {
          // Re-calculate the pantry items with the latest image URLs from state
          final livePantryItems = _remotePantryItems.map((item) {
            final name = item['name']?.toString() ?? '';
            return {
              'name': name,
              'quantity': (item['quantity'] as num?)?.toDouble() ?? 1.0,
              'unit': item['unit']?.toString() ?? 'pcs',
              'imageUrl': pantryState.getItemImage(name) ?? '', 
              'price': (item['price'] as num?)?.toDouble() ?? 0.0,
              'source': item['source']?.toString() ?? 'manual',
              '_id': item['_id']?.toString() ?? '',
            };
          }).toList();

          final liveGroupedItems = _getGroupedItems(livePantryItems);

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---------- SEARCH ----------
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PantrySearchAddScreen(),
                      ),
                    );
                  },
                  child: AbsorbPointer(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Search Items",
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ---------- INFO CARDS ----------
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ShoppingListScreen(),
                            ),
                          );
                        },
                        child: Consumer<ShoppingListService>(
                          builder: (_, shoppingService, __) {
                            return _infoCard(
                              shoppingService.items.length.toString(),
                              "items",
                              "in shopping list",
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LowStockItemsScreen(),
                            ),
                          );
                        },
                        child: _infoCard(
                          lowStockItemCount.toString(),
                          "items",
                          "in low stock",
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ---------- CATEGORIES ----------
                ...liveGroupedItems.entries.map((e) {
                  return _categorySection(
                    title: e.key,
                    items: e.value,
                    allPantryItems: livePantryItems, // Pass the live items
                  );
                }),
              ],
            ),
          );
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kAccent,
        onPressed: () => _showAddItemsBottomSheet(context),
        icon: const Icon(Icons.add),
        label: const Text("Add Items"),
      ),
    );
  }

  // ---------- UI COMPONENTS ----------

  Widget _infoCard(String count, String label1, String label2) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: kLightAccent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            count,
            style: const TextStyle(
              color: kAccent,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black54, fontSize: 12),
              children: [
                TextSpan(text: label1, style: const TextStyle(fontWeight: FontWeight.w600)),
                const TextSpan(text: " "),
                TextSpan(text: label2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _categorySection({
  required String title,
  required List<Map<String, dynamic>> items,
  required List<Map<String, dynamic>> allPantryItems,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          // ✅ SEE ALL BUTTON (FIXED)
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CategoryItemsScreen(
          category: title, // 🔥 PASS CATEGORY NAME
          allItems: allPantryItems,
                  ),
                ),
              );
            },
            child: const Text(
              'All →',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),

      const SizedBox(height: 12),

      SizedBox(
        height: 180, // Increased from 140 to 180 to accommodate larger images
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, index) {
            final item = items[index];
            final itemName = item['name'] as String;
            final isSelected = _selectedItems.contains(itemName);
            
            return GestureDetector(
              onTap: () {
                if (_isSelectionMode) {
                  _toggleItemSelection(itemName);
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PantryItemDetailsScreen(item: item),
                    ),
                  );
                }
              },
              onLongPress: () {
                if (!_isSelectionMode) {
                  setState(() {
                    _isSelectionMode = true;
                    _selectedItems.add(itemName);
                  });
                }
              },
              child: _itemCard(
                item, 
                isSelected: isSelected,
                isSelectionMode: _isSelectionMode
              ),
            );
          },
        ),
      ),

      const SizedBox(height: 24),
    ],
  );
}


  Widget _itemCard(Map<String, dynamic> item, {bool isSelected = false, bool isSelectionMode = false}) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.red.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? Colors.red : Colors.grey.shade300,
          width: isSelected ? 2 : 1
        ),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image takes most of the space
              Expanded(
                flex: 3,
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildItemImage(item),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Name takes minimal space
              Center(
                child: Text(
                  item['name'],
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Add to shopping list button - compact with toggle state
              Consumer<ShoppingListService>(
                builder: (_, shoppingService, __) {
                  final isAdded = shoppingService.isAdded(item['name']);
                  return GestureDetector(
                    onTap: () => isAdded ? _removeFromShoppingList(item) : _addToShoppingList(item),
                    child: Container(
                      width: double.infinity,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isAdded ? Colors.green.shade100 : Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isAdded ? Colors.green.shade300 : Colors.orange.shade300, 
                          width: 0.5
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isAdded ? Icons.check_circle_outline : Icons.shopping_cart_outlined,
                            size: 14,
                            color: isAdded ? Colors.green.shade700 : Colors.orange.shade700,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            isAdded ? 'Added' : 'Add',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isAdded ? Colors.green.shade700 : Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          
          // Selection Checkbox Overlay
          if (isSelectionMode)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.red : Colors.white.withOpacity(0.8),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.red : Colors.grey,
                  ),
                ),
                child: Icon(
                  Icons.check,
                  size: 14,
                  color: isSelected ? Colors.white : Colors.transparent,
                ),
              ),
            ),
        ],
      ),
    );
  }

// Helper method to build the item image
Widget _buildItemImage(Map<String, dynamic> item) {
  final imageUrl = item['imageUrl']?.toString();
  final itemName = item['name']?.toString() ?? '';
  
  print('🖼️ DEBUG: Building image for $itemName, imageUrl: $imageUrl');
  
  // If we have a valid imageUrl, try to use network image
  if (imageUrl != null && imageUrl.isNotEmpty && !imageUrl.contains('temp_pantry')) {
    print('🖼️ DEBUG: Using network image for $itemName');
    return Image.network(
      imageUrl,
      width: 120,
      height: 120,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        print('❌ DEBUG: Network image failed for $itemName: $error, falling back to ItemImageResolver');
        return ItemImageResolver.getImageWidget(
          itemName,
          size: 120,
          imageUrl: null, // Don't pass the failed imageUrl
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.grey.shade100,
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
    );
  }
  
  // Otherwise, use the ItemImageResolver which handles local assets and backend generation
  print('🖼️ DEBUG: Using ItemImageResolver for $itemName');
  return ItemImageResolver.getImageWidget(
    itemName,
    size: 120,
    imageUrl: imageUrl, // Pass imageUrl (might be null or fallback)
  );
}

  // ---------------- CLEAR ALL FUNCTIONALITY ----------------
  void _showClearAllConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Clear All Pantry Items',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you sure you want to remove all pantry items from the remote server?',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Text(
                'This will delete ${pantryItems.length} items:',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: pantryItems.take(10).map((item) => Chip(
                  label: Text(
                    item['name'],
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: Colors.grey.shade200,
                )).toList(),
              ),
              if (pantryItems.length > 10)
                Text(
                  '... and ${pantryItems.length - 10} more items',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              const SizedBox(height: 16),
              const Text(
                '⚠️ This action cannot be undone!',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _clearAllPantryItems();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Clear All'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _clearAllPantryItems() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Clearing pantry items...'),
            ],
          ),
        );
      },
    );

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final String? userId = authService.user?.mobile_no;
      
      final success = await _pantryListService.clearAllPantryItems(userId: userId);
      
      // Close loading dialog
      Navigator.of(context).pop();

      if (success) {
        // Clear local pantry state
        final pantryState = Provider.of<PantryState>(context, listen: false);
        await pantryState.clearAllItems();
        
        // Clear remote items cache
        setState(() {
          _remotePantryItems.clear();
        });
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pantry cleared successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to clear pantry items. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error clearing pantry: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // ---------------- DELETE SELECTED FUNCTIONALITY ----------------
  void _showDeleteSelectedConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Delete ${_selectedItems.length} Items?',
            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Are you sure you want to remove these items from your pantry?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteSelectedItems();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteSelectedItems() async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final String? userId = authService.user?.mobile_no;
      
      // Find the full item objects for the selected names
      final itemsToDelete = _remotePantryItems
          .where((item) => _selectedItems.contains(item['name']))
          .toList();

      final success = await _pantryListService.removePantryItems(itemsToDelete, userId: userId);
      
      Navigator.pop(context); // Close loading

      if (success) {
        // Update local state
        final pantryState = Provider.of<PantryState>(context, listen: false);
        await pantryState.removeItems(_selectedItems.toList());
        
        setState(() {
          _remotePantryItems.removeWhere((item) => _selectedItems.contains(item['name']));
          _selectedItems.clear();
          _isSelectionMode = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Items deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete items'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting items: $e'), backgroundColor: Colors.red),
      );
    }
  }



  // ---------------- ADD TO SHOPPING LIST ----------------
  void _addToShoppingList(Map<String, dynamic> item) {
    debugPrint('=== PantryHomeScreen._addToShoppingList ===');
    debugPrint('Adding item: ${item['name']}');
    
    final shoppingService = Provider.of<ShoppingListService>(context, listen: false);
    
    // Get item details from remote pantry data
    final name = item['name'] as String;
    final quantity = item['quantity'] is num ? (item['quantity'] as num).toDouble() : 1.0;
    final unit = item['unit'] as String? ?? 'pcs';
    final category = CategoryEngine.getCategory(name);
    final imageUrl = item['imageUrl'] as String? ?? '';
    
    debugPrint('  - Name: $name');
    debugPrint('  - Quantity: $quantity');
    debugPrint('  - Unit: $unit');
    debugPrint('  - Category: $category');
    
    shoppingService.addItem(
      name: name,
      quantity: quantity,
      unit: unit,
      category: category,
      imageUrl: imageUrl,
    );
    
    debugPrint('✅ Item added to shopping list');
    debugPrint('==============================');
  }

  // ---------------- REMOVE FROM SHOPPING LIST ----------------
  void _removeFromShoppingList(Map<String, dynamic> item) {
    debugPrint('=== PantryHomeScreen._removeFromShoppingList ===');
    debugPrint('Removing item: ${item['name']}');
    
    final shoppingService = Provider.of<ShoppingListService>(context, listen: false);
    shoppingService.removeItem(item['name']);
  }

  // ---------------- ADD ITEMS BOTTOM SHEET ----------------
  void _showAddItemsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Hey there!",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text(
                "How do you want to add items to your pantry?",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kAccent,
                    side: const BorderSide(color: kAccent, width: 1.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PantrySearchAddScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Search & Add',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAccent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const IngredientEntryScreen(
                          mode: ScanMode.pantry,
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'Upload / Take a Photo',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
