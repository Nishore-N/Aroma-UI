import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PantryState extends ChangeNotifier {
  final Map<String, String> _itemImages = {};
  final List<PantryItem> _items = [];

  // Consistent normalization for image keys
  String _normalizeName(String name) => name.toLowerCase().trim();

  Map<String, double> get pantryQty => { for (var item in _items) item.name : item.quantity };
  Map<String, String> get pantryUnit => { for (var item in _items) item.name : item.unit };
  List<PantryItem> get items => List.from(_items);

  // Get image for an item - prioritize memory cache, then item property
  String? getItemImage(String name) {
    final normalized = _normalizeName(name);
    if (_itemImages.containsKey(normalized)) return _itemImages[normalized];
    final item = _items.firstWhere((e) => _normalizeName(e.name) == normalized, orElse: () => PantryItem(name: '', quantity: 0, unit: ''));
    return item.imageUrl;
  }

  Map<String, String> get pantryImages {
    final Map<String, String> images = Map.from(_itemImages);
    for (final item in _items) {
      if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
        images[item.name] = item.imageUrl!;
      }
    }
    return images;
  }

  List<PantryItem> get pantryItems => List.from(_items);
  static const String _storageKey = 'pantry_data';

  // LOAD PANTRY FROM LOCAL STORAGE
  Future<void> loadPantry() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    _itemImages.clear();
    _items.clear();

    if (raw != null) {
      final decoded = jsonDecode(raw) as List<dynamic>;

      for (final item in decoded) {
        final name = item['name'] as String;
        final qty = (item['quantity'] as num).toDouble();
        final unit = item['unit'] as String;
        final imageUrl = item['imageUrl'] as String?;

        _items.add(
          PantryItem(
            name: name,
            quantity: qty,
            unit: unit,
            imageUrl: imageUrl,
          ),
        );
      }
    }

    // Load generated image cache
    final imageCacheRaw = prefs.getString('pantry_image_cache');
    if (imageCacheRaw != null) {
      try {
        final Map<String, dynamic> cache = jsonDecode(imageCacheRaw);
        cache.forEach((key, value) {
          _itemImages[_normalizeName(key)] = value.toString();
        });
      } catch (e) {
        debugPrint("❌ Error loading image cache: $e");
      }
    }

    notifyListeners();
  }

  // ADD / UPDATE ITEM
  // ADD / UPDATE ITEM
  Future<void> setItem(String name, double qty, String unit, {String? imageUrl}) async {
    debugPrint(" PANTRY SET: $name → $qty $unit $imageUrl"); // 
    
    // Update image cache if a new URL is provided
    if (imageUrl != null && imageUrl.isNotEmpty) {
      _itemImages[_normalizeName(name)] = imageUrl;
    }

    final index = _items.indexWhere((e) => e.name == name);
    if (index >= 0) {
      _items[index] = PantryItem(
        name: name,
        quantity: qty,
        unit: unit,
        imageUrl: imageUrl ?? _items[index].imageUrl, // Keep existing if null
      );
    } else {
      _items.add(
        PantryItem(
          name: name,
          quantity: qty,
          unit: unit,
          imageUrl: imageUrl,
        ),
      );
    }

    await _savePantry();
    notifyListeners();
  }

  // Update only the image for an item
  Future<void> updateItemImage(String name, String imageUrl) async {
    final normalized = _normalizeName(name);
    _itemImages[normalized] = imageUrl;
    
    final index = _items.indexWhere((e) => _normalizeName(e.name) == normalized);
    if (index >= 0) {
      _items[index].imageUrl = imageUrl;
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pantry_image_cache', jsonEncode(_itemImages));
    notifyListeners();
  }

  double getQty(String name) {
    final item = _items.firstWhere((e) => e.name == name, orElse: () => PantryItem(name: '', quantity: 0, unit: ''));
    return item.quantity;
  }

  bool isLowStock(String name, {double threshold = 3}) {
    return getQty(name) > 0 && getQty(name) <= threshold;
  }

  // CLEAR ALL ITEMS
  Future<void> clearAllItems() async {
    debugPrint("🗑️ Clearing all pantry items from local state...");
    _itemImages.clear();
    _items.clear();
    await _savePantry();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pantry_image_cache');
    
    notifyListeners();
    debugPrint("✅ Local pantry state and image cache cleared");
  }

  // REMOVE MULTIPLE ITEMS
  Future<void> removeItems(List<String> itemNames) async {
    if (itemNames.isEmpty) return;
    
    debugPrint("🗑️ Removing ${itemNames.length} items from local state");
    
    // Normalize names for comparison
    final normalizedNamesToRemove = itemNames.map(_normalizeName).toSet();
    
    // Remove from items list
    _items.removeWhere((item) => normalizedNamesToRemove.contains(_normalizeName(item.name)));
    
    // Remove from image cache
    for (final name in normalizedNamesToRemove) {
      _itemImages.remove(name);
    }
    
    await _savePantry();
    notifyListeners();
  }

  // SAVE TO LOCAL STORAGE
  Future<void> _savePantry() async {
    final prefs = await SharedPreferences.getInstance();

    final data = _items
        .map(
          (e) => {
            'name': e.name,
            'quantity': e.quantity,
            'unit': e.unit,
            'imageUrl': e.imageUrl, // Include imageUrl in save
          },
        )
        .toList();

    await prefs.setString(_storageKey, jsonEncode(data));
  }
}

class PantryItem {
  final String name;
  final double quantity;
  final String unit;
  String? imageUrl; // Remove public modifier and make it a regular field

  PantryItem({
    required this.name,
    required this.quantity,
    required this.unit,
    this.imageUrl,
  });
}