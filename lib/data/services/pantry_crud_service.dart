import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../../core/constants/api_endpoints.dart';

class PantryCrudService {
  // API endpoints
  static String get _baseUrl => ApiEndpoints.baseUrl;
  static String get _listUrl => ApiEndpoints.pantryList;
  static String get _addUrl => ApiEndpoints.pantryAdd;
  static String get _removeUrl => ApiEndpoints.pantryRemove;

  // 🔹 READ: Get all pantry items
  Future<List<Map<String, dynamic>>> getPantryItems({String? userId}) async {
    try {
      debugPrint("📤 Fetching pantry items...");
      
      String url = _listUrl;
      if (userId != null && userId.isNotEmpty) {
        url = "$url?userId=$userId";
      }
      debugPrint("🔗 Calling URL: $url");
      
      final dio = Dio();
      final response = await dio.get(url);
      
      if (response.statusCode == 200 && response.data['status'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        final items = List<Map<String, dynamic>>.from(data);
        debugPrint("✅ Retrieved ${items.length} pantry items");
        return items;
      } else {
        debugPrint("❌ Failed to fetch pantry items: ${response.data}");
        return [];
      }
    } catch (e) {
      debugPrint("❌ Error fetching pantry items: $e");
      return [];
    }
  }

  // 🔹 CREATE: Add pantry items
  Future<Map<String, dynamic>> addPantryItems(List<Map<String, dynamic>> items, {String? userId}) async {
    try {
      debugPrint("📤 Adding ${items.length} pantry items...");
      
      // Convert items to the format expected by the API
      final ingredientsWithQuantity = items.map((item) => {
        "item": item['name']?.toString() ?? '',
        "price": (item['price'] as num?)?.toDouble() ?? 0.0,
        "quantity": (item['quantity'] as num?)?.toDouble() ?? 1.0,
      }).toList();
      
      // Create the request body in the correct format
      final requestBody = {
        if (userId != null) "userId": userId,
        "ingredients_with_quantity": ingredientsWithQuantity,
        "message": "Food items extracted successfully",
        "raw_text": jsonEncode({
          "ingredients_with_quantity": ingredientsWithQuantity,
          "message": "Extracted food items from scan",
          "status": true,
        }),
        "status": true,
      };
      
      String url = _addUrl;
      if (userId != null && userId.isNotEmpty) {
        url = "$url?userId=$userId";
      }
      debugPrint("🔗 Calling URL: $url");
      debugPrint("📦 Add request body: $requestBody");
      
      final dio = Dio();
      final response = await dio.post(url, data: requestBody);
      
      debugPrint("✅ Pantry items added: ${response.data}");
      return response.data;
    } catch (e) {
      debugPrint("❌ Error adding pantry items: $e");
      rethrow;
    }
  }

  // 🔹 DELETE: Remove pantry items
  Future<Map<String, dynamic>> removePantryItems(List<Map<String, dynamic>> items, {String? userId}) async {
    try {
      debugPrint("🗑️ Removing ${items.length} pantry items...");
      
      // Convert items to the format expected by the API
      final ingredientsWithQuantity = items.map((item) => {
        "item": item['name']?.toString() ?? '',
        "price": (item['price'] as num?)?.toDouble() ?? 0.0,
        "quantity": (item['quantity'] as num?)?.toDouble() ?? 1.0,
      }).toList();
      
      // Create the request body in the correct format
      final requestBody = {
        if (userId != null) "userId": userId,
        "ingredients_with_quantity": ingredientsWithQuantity,
        "message": "Food items extracted successfully",
        "raw_text": jsonEncode({
          "ingredients_with_quantity": ingredientsWithQuantity,
          "message": "Extracted food items from scan",
          "status": true,
        }),
        "status": true,
      };
      
      String url = _removeUrl;
      if (userId != null && userId.isNotEmpty) {
        url = "$url?userId=$userId";
      }
      debugPrint("🔗 Calling URL: $url");
      debugPrint("📦 Remove request body: $requestBody");
      
      final dio = Dio();
      final response = await dio.post(url, data: requestBody);
      
      debugPrint("✅ Pantry items removed: ${response.data}");
      return response.data;
    } catch (e) {
      debugPrint("❌ Error removing pantry items: $e");
      rethrow;
    }
  }

  // 🔹 DELETE: Clear all pantry items
  Future<bool> clearAllPantryItems({String? userId}) async {
    try {
      debugPrint("🗑️ Clearing all pantry items...");
      
      // 1. Fetch current items to know what to delete
      final currentItems = await getPantryItems(userId: userId);
      
      if (currentItems.isEmpty) {
        debugPrint("✅ Pantry is already empty");
        return true;
      }

      // 2. Remove all items using remote endpoint
      await removePantryItems(currentItems, userId: userId);
      
      debugPrint("✅ All pantry items cleared from server");
      return true;
    } catch (e) {
      debugPrint("❌ Error clearing pantry items: $e");
      
      // Even if server fails, we might want to return false so UI knows
      // But for now, we'll assume if it fails, it fails.
      return false;
    }
  }

  // 🔹 UPDATE: Update pantry item quantity (true SET behavior)
  Future<void> updatePantryItem(String itemName, double newQuantity, {String? userId, double? price, String? unit}) async {
    try {
      debugPrint("🔄 SETTING pantry item: $itemName to total quantity: $newQuantity for user: $userId");
      
      // 1. Remove ALL existing instances of this item first to ensure we don't increment
      // We call removeSingleItem without passing qty/price so it fetches current and clears it
      await removeSingleItem(itemName, userId: userId);
      
      // 2. Add it back with the absolute new quantity
      if (newQuantity > 0) {
        await addPantryItems([{
          'name': itemName,
          'quantity': newQuantity,
          'price': price ?? 0.0,
          'unit': unit ?? 'pcs',
        }], userId: userId);
      }
      
      debugPrint("✅ Pantry item $itemName set to $newQuantity successfully");
    } catch (e) {
      debugPrint("❌ Error updating pantry item $itemName: $e");
      rethrow;
    }
  }

  // 🔹 HELPER: Add single item
  Future<Map<String, dynamic>> addSingleItem(String name, double quantity, {String? userId, double? price}) async {
    return await addPantryItems([{
      'name': name,
      'quantity': quantity,
      'price': price ?? 0.0,
    }], userId: userId);
  }

  // 🔹 HELPER: Remove single item
  Future<Map<String, dynamic>> removeSingleItem(String name, {String? userId, double? quantity, double? price}) async {
    // Get current item details if not provided
    if (quantity == null || price == null) {
      final currentItems = await getPantryItems(userId: userId);
      final item = currentItems.firstWhere(
        (item) => item['name'].toString().toLowerCase() == name.toLowerCase(),
        orElse: () => {},
      );
      
      if (item.isNotEmpty) {
        quantity = (item['quantity'] as num?)?.toDouble();
        price = (item['price'] as num?)?.toDouble();
      }
    }
    
    // Create the request body in the exact format expected by the API
    final requestBody = {
      if (userId != null) "userId": userId,
      "ingredients_with_quantity": [
        {
          "item": name,
          "price": price ?? 0.0,
          "quantity": quantity?.toDouble() ?? 1.0,
        }
      ],
      "message": "Food items extracted successfully",
      "raw_text": "{\n  \"ingredients_with_quantity\": [\n    {\n      \"item\": \"$name\",\n      \"quantity\": ${quantity?.toDouble() ?? 1.0},\n      \"price\": ${price ?? 0.0}\n    }\n  ],\n  \"message\": \"Food items with quantities and prices extracted from the receipt.\",\n  \"status\": true,\n  \"raw_text\": \"$name ${price ?? 0.0}\"\n}",
      "status": true,
    };
    
    String url = _removeUrl;
    if (userId != null && userId.isNotEmpty) {
      url = "$url?userId=$userId";
    }
    debugPrint("📦 Remove request body for '$name': $requestBody");
    debugPrint("🔗 Calling URL: $url");
    
    final dio = Dio();
    final response = await dio.post(url, data: requestBody);
    
    debugPrint("✅ Remove response for '$name': ${response.data}");
    return response.data;
  }
}
