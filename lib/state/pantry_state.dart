import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PantryState extends ChangeNotifier {
  final Map<String, double> _pantryQty = {};
  final Map<String, String> _pantryUnit = {};
  final List<PantryItem> _items = [];

  Map<String, double> get pantryQty => _pantryQty;
  Map<String, String> get pantryUnit => _pantryUnit;
  List<PantryItem> get items => List.from(_items);

  // Add pantryImages getter for low stock screen compatibility
  Map<String, String> get pantryImages {
    final Map<String, String> images = {};
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

    _pantryQty.clear();
    _pantryUnit.clear();
    _items.clear();

    if (raw != null) {
      final decoded = jsonDecode(raw) as List<dynamic>;

      for (final item in decoded) {
        final name = item['name'] as String;
        final qty = (item['quantity'] as num).toDouble();
        final unit = item['unit'] as String;
        final imageUrl = item['imageUrl'] as String?;

        _pantryQty[name] = qty;
        _pantryUnit[name] = unit;
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

    notifyListeners();
  }

  // ADD / UPDATE ITEM
  // ADD / UPDATE ITEM
  Future<void> setItem(String name, double qty, String unit, {String? imageUrl}) async {
    debugPrint(" PANTRY SET: $name → $qty $unit $imageUrl"); // 
    _pantryQty[name] = qty;
    _pantryUnit[name] = unit;

    final index = _items.indexWhere((e) => e.name == name);
    if (index >= 0) {
      _items[index] = PantryItem(
        name: name,
        quantity: qty,
        unit: unit,
        imageUrl: imageUrl, // Pass imageUrl
      );
    } else {
      _items.add(
        PantryItem(
          name: name,
          quantity: qty,
          unit: unit,
          imageUrl: imageUrl, // Pass imageUrl
        ),
      );
    }

    await _savePantry();
    notifyListeners();
  }

  double getQty(String name) => _pantryQty[name] ?? 0;

  bool isLowStock(String name, {double threshold = 3}) {
    return getQty(name) > 0 && getQty(name) <= threshold;
  }

  // CLEAR ALL ITEMS
  Future<void> clearAllItems() async {
    debugPrint("🗑️ Clearing all pantry items from local state...");
    _pantryQty.clear();
    _pantryUnit.clear();
    _items.clear();
    await _savePantry();
    notifyListeners();
    debugPrint("✅ Local pantry state cleared");
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