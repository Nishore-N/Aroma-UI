import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/services/pantry_crud_service.dart';

class PantryState extends ChangeNotifier {
  final Map<String, String> _itemImages = {};
  final List<PantryItem> _items = [];

  // Consistent normalization for image keys
  String _normalizeName(String name) => name.toLowerCase().trim();

  Map<String, double> get pantryQty => { for (var item in _items) item.name : item.quantity };
  Map<String, String> get pantryUnit => { for (var item in _items) item.name : item.unit };
  List<PantryItem> get items => List.unmodifiable(_items);

  // Centralized low stock count logic (qty > 0 and qty <= 3)
  int get lowStockCount {
    return _items.where((item) => item.quantity > 0 && item.quantity <= 3).length;
  }

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
        try {
          _items.add(PantryItem.fromJson(item as Map<String, dynamic>));
        } catch (e) {
          debugPrint("❌ Error parsing local pantry item: $e");
        }
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
  Future<void> setItem(String name, double qty, String unit, {String? imageUrl, double? price, String? source, String? id}) async {
    debugPrint(" PANTRY SET: $name → $qty $unit $imageUrl"); // 
    
    // Update image cache if a new URL is provided
    if (imageUrl != null && imageUrl.isNotEmpty) {
      _itemImages[_normalizeName(name)] = imageUrl;
    }

    final index = _items.indexWhere((e) => _normalizeName(e.name) == _normalizeName(name));
    if (index >= 0) {
      _items[index] = PantryItem(
        id: id ?? _items[index].id,
        name: name,
        quantity: qty,
        unit: unit,
        imageUrl: imageUrl ?? _items[index].imageUrl, // Keep existing if null
        price: price ?? _items[index].price,
        source: source ?? _items[index].source,
        usageHistory: _items[index].usageHistory,
      );
    } else {
      _items.add(
        PantryItem(
          id: id,
          name: name,
          quantity: qty,
          unit: unit,
          imageUrl: imageUrl,
          price: price,
          source: source,
        ),
      );
    }

    // 🚀 Optimistic Update
    notifyListeners();
    await _savePantry();
  }

  // UPDATE QUANTITY (Sync with Remote)
  Future<void> updateQuantity(String name, double qty, {String? userId}) async {
    try {
      if (qty <= 0) {
        await removeItems([name], userId: userId);
        return;
      }

      final index = _items.indexWhere((e) => _normalizeName(e.name) == _normalizeName(name));
      if (index >= 0) {
        final item = _items[index];
        _items[index] = PantryItem(
          id: item.id,
          name: item.name,
          quantity: qty,
          unit: item.unit,
          imageUrl: item.imageUrl,
          price: item.price,
          source: item.source,
          usageHistory: item.usageHistory,
        );
        
        // 🚀 Optimistic Update: Notify listeners immediately
        notifyListeners();
        
        // Sync with remote
        await PantryCrudService().updatePantryItem(
          name, 
          qty, 
          userId: userId,
          unit: item.unit,
        );
        
        await _savePantry();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("❌ Error updating quantity: $e");
    }
  }

  // RECORD USAGE
  Future<void> recordUsage(List<String> ingredientNames) async {
    final now = DateTime.now();
    bool changed = false;
    
    for (final name in ingredientNames) {
      final normalized = _normalizeName(name);
      final index = _items.indexWhere((e) => _normalizeName(e.name) == normalized);
      
      if (index >= 0) {
        _items[index].recordUsage(now);
        changed = true;
      }
    }
    
    if (changed) {
      await _savePantry();
      notifyListeners();
    }
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
    final normalized = _normalizeName(name);
    final item = _items.firstWhere(
      (e) => _normalizeName(e.name) == normalized, 
      orElse: () => PantryItem(name: '', quantity: 0, unit: '')
    );
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

  // REMOVE MULTIPLE ITEMS (Sync with Remote)
  Future<void> removeItems(List<String> itemNames, {String? userId}) async {
    if (itemNames.isEmpty) return;
    
    debugPrint("🗑️ Removing ${itemNames.length} items from state (UserId: $userId)");
    
    // Normalize names for comparison
    final normalizedNamesToRemove = itemNames.map(_normalizeName).toSet();
    
    // Collect data for remote sync before removing from local list
    final itemsToRemoveData = _items
        .where((item) => normalizedNamesToRemove.contains(_normalizeName(item.name)))
        .map((item) => {
          'name': item.name,
          'quantity': item.quantity,
          'price': item.price,
        }).toList();

    // 1. Remove from local items list
    _items.removeWhere((item) => normalizedNamesToRemove.contains(_normalizeName(item.name)));
    
    // 2. Remove from image cache
    for (final name in normalizedNamesToRemove) {
      _itemImages.remove(name);
    }
    
    // 3. 🚀 Optimistic Update
    notifyListeners();
    await _savePantry();

    // 4. Sync with remote
    if (itemsToRemoveData.isNotEmpty) {
      try {
        await PantryCrudService().removePantryItems(itemsToRemoveData, userId: userId);
        debugPrint("✅ Remote removal successful");
      } catch (e) {
        debugPrint("❌ Remote removal failed: $e");
        // We might want to revert local changes here, but sticking to optimistic for now
      }
    }
  }

  // SAVE TO LOCAL STORAGE
  Future<void> _savePantry() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _items.map((e) => e.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(data));
  }

  // SET ITEMS FROM REMOTE
  Future<void> setRemoteItems(List<Map<String, dynamic>> remoteItems) async {
    debugPrint("🔄 Syncing ${remoteItems.length} remote items to local state...");
    
    _items.clear();

    for (final item in remoteItems) {
      final id = item['_id']?.toString();
      final name = item['name'] ?? '';
      final qty = (item['quantity'] ?? 0).toDouble();
      final unit = item['unit'] ?? '';
      final imageUrl = item['imageUrl'];
      final price = (item['price'] as num?)?.toDouble();
      final source = item['source']?.toString();

      if (name.isNotEmpty) {
        // Fallback: If remote imageUrl is missing, try to get it from local cache
        final effectiveImageUrl = (imageUrl != null && imageUrl.isNotEmpty) 
            ? imageUrl 
            : getItemImage(name);

        _items.add(
          PantryItem(
            id: id,
            name: name,
            quantity: qty,
            unit: unit,
            imageUrl: effectiveImageUrl,
            price: price,
            source: source,
            usageHistory: [], // New items from remote start fresh or we could sync this later
          ),
        );
        
        // Update image cache if URL exists
        if (effectiveImageUrl != null && effectiveImageUrl.isNotEmpty) {
          _itemImages[_normalizeName(name)] = effectiveImageUrl;
        }
      }
    }

    await _savePantry();
    notifyListeners();
  }

  // SYNC WITH SERVER
  Future<void> syncFromRemote(String? userId) async {
    try {
      debugPrint("🔄 Triggering remote sync for user: $userId");
      final remoteItems = await PantryCrudService().getPantryItems(userId: userId);
      await setRemoteItems(remoteItems);
    } catch (e) {
      debugPrint("❌ Error syncing from remote: $e");
    }
  }
}

class PantryItem {
  final String? id; // Server ID (_id)
  final String name;
  final double quantity;
  final String unit;
  String? imageUrl; 
  final double? price;
  final String? source;
  final List<DateTime>? _usageHistory;
  
  // Resilient getter for usageHistory to handle null safely during hot reload
  List<DateTime> get usageHistory => _usageHistory ?? [];

  PantryItem({
    this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    this.imageUrl,
    this.price,
    this.source,
    List<DateTime>? usageHistory,
  }) : _usageHistory = usageHistory ?? [];

  void recordUsage(DateTime timestamp) {
    usageHistory.add(timestamp);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'quantity': quantity,
    'unit': unit,
    'imageUrl': imageUrl,
    'price': price,
    'source': source,
    'usageHistory': usageHistory.map((d) => d.toIso8601String()).toList(),
  };

  factory PantryItem.fromJson(Map<String, dynamic> json) {
    final usageHistoryRaw = json['usageHistory'] as List<dynamic>?;
    final usageHistory = usageHistoryRaw != null
        ? usageHistoryRaw.map((e) => DateTime.parse(e.toString())).toList()
        : <DateTime>[];

    return PantryItem(
      id: json['id'] as String?,
      name: json['name'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String,
      imageUrl: json['imageUrl'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      source: json['source'] as String?,
      usageHistory: usageHistory,
    );
  }
}