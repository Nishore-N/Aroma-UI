import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'pantry_crud_service.dart';

class PantryListService {
  final PantryCrudService _crudService = PantryCrudService();

  /// Fetch all pantry items from remote server
  Future<List<Map<String, dynamic>>> fetchPantryItems() async {
    try {
      // Use the new CRUD service
      final items = await _crudService.getPantryItems();
      debugPrint("✅ [PantryList] Retrieved ${items.length} items from remote server");
      return items;
    } catch (e) {
      debugPrint("❌ Remote pantry fetch failed: $e");
      // Fallback to local storage if remote fails
      return await _fetchPantryFromLocal();
    }
  }

  /// Clear all pantry items from remote server
  Future<bool> clearAllPantryItems() async {
    try {
      debugPrint("🗑️ [PantryList] Clearing all pantry items from remote server...");
      
      final success = await _crudService.clearAllPantryItems();
      
      if (success) {
        debugPrint("✅ [PantryList] Successfully cleared all pantry items");
        return true;
      } else {
        debugPrint("❌ [PantryList] Failed to clear pantry items");
        return false;
      }
    } catch (e) {
      debugPrint("❌ [PantryList] Exception while clearing pantry: $e");
      return false;
    }
  }

  /// Fallback method to get pantry items from local SharedPreferences
  Future<List<Map<String, dynamic>>> _fetchPantryFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('pantry_data');
      
      if (raw != null) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        debugPrint("✅ [PantryList] Retrieved ${decoded.length} items from local storage");
        return List<Map<String, dynamic>>.from(decoded);
      }
      return [];
    } catch (e) {
      debugPrint("❌ Local pantry fetch failed: $e");
      return [];
    }
  }
}
