import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShoppingListService extends ChangeNotifier {
  static const _storageKey = 'shopping_list_items';

  final List<Map<String, dynamic>> _items = [];

  List<Map<String, dynamic>> get items => _items;

  ShoppingListService() {
    _loadFromStorage();
  }

  // -------- LOAD --------
  Future<void> _loadFromStorage() async {
    debugPrint('=== ShoppingListService._loadFromStorage ===');
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);

      if (raw != null) {
        final List decoded = jsonDecode(raw);
        _items
          ..clear()
          ..addAll(List<Map<String, dynamic>>.from(decoded));
        debugPrint('✅ Loaded ${_items.length} items from storage');
        for (var item in _items) {
          debugPrint('  - ${item['name']} (${item['quantity']} ${item['unit']})');
        }
      } else {
        debugPrint('ℹ️ No items found in storage - first time use');
      }
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading shopping list: $e');
    }
    debugPrint('====================================');
  }

  // -------- SAVE --------
  Future<void> _saveToStorage() async {
    debugPrint('=== ShoppingListService._saveToStorage ===');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(_items));
      debugPrint('✅ Saved ${_items.length} items to storage');
      debugPrint('Saved data: ${jsonEncode(_items)}');
    } catch (e) {
      debugPrint('❌ Error saving shopping list: $e');
    }
    debugPrint('====================================');
  }

  // -------- ADD ITEM --------
  void addItem({
    required String name,
    required dynamic quantity,
    required String unit,
    required String category,
    String? imageUrl,
  }) {
    debugPrint('=== ShoppingListService.addItem ===');
    debugPrint('Name: $name, Qty: $quantity, Unit: $unit, Category: $category, ImageUrl: $imageUrl');
    
    final index = _items.indexWhere((e) => e['name'] == name);

    if (index >= 0) {
      _items[index]['quantity'] = quantity.toString();
      if (imageUrl != null) {
        _items[index]['imageUrl'] = imageUrl;
      }
      debugPrint('Updated existing item at index $index');
    } else {
      _items.add({
        'name': name,
        'quantity': quantity.toString(),
        'unit': unit,
        'category': category,
        'imageUrl': imageUrl,
      });
      debugPrint('Added new item. Total items now: ${_items.length}');
    }

    debugPrint('Current items: $_items');
    _saveToStorage();
    notifyListeners();
    debugPrint('==============================');
  }

  // -------- UPDATE ITEM --------
  void updateItem(String name, String quantity, String unit) {
    debugPrint('=== ShoppingListService.updateItem ===');
    debugPrint('Name: $name, Qty: $quantity, Unit: $unit');
    
    final index = _items.indexWhere((e) => e['name'] == name);
    
    if (index >= 0) {
      _items[index]['quantity'] = quantity;
      _items[index]['unit'] = unit;
      _saveToStorage();
      notifyListeners();
    }
  }

  // -------- REMOVE --------
  void removeItem(String name) {
    _items.removeWhere((e) => e['name'] == name);
    _saveToStorage();
    notifyListeners();
  }

  // -------- CLEAR --------
  void clearAll() {
    _items.clear();
    _saveToStorage();
    notifyListeners();
  }

  bool isAdded(String name) {
    return _items.any((e) => e['name'] == name);
  }

  // -------- TEST METHOD --------
  void addTestItems() {
    debugPrint('=== ShoppingListService.addTestItems ===');
    final testItems = [
      {'name': 'Butter', 'quantity': '2', 'unit': 'pcs', 'category': 'Dairy'},
      {'name': 'Cheese', 'quantity': '3', 'unit': 'pcs', 'category': 'Dairy'},
      {'name': 'Bread', 'quantity': '1', 'unit': 'loaf', 'category': 'Bakery'},
    ];
    
    for (final item in testItems) {
      addItem(
        name: item['name'] as String,
        quantity: item['quantity'] as String,
        unit: item['unit'] as String,
        category: item['category'] as String,
      );
    }
    debugPrint('==============================');
  }

  // -------- RELOAD METHOD --------
  Future<void> reloadFromStorage() async {
    debugPrint('=== ShoppingListService.reloadFromStorage ===');
    await _loadFromStorage();
    debugPrint('==============================');
  }
}