import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/services/ingredient_image_service.dart';
import '../../ui/widgets/ingredient_image_widget.dart';

class ItemImageResolver {
  static const String _basePath = "assets/images/pantry/";
  static const String _fallback = "temp_pantry.png";
  static Set<String>? _assetPaths;

  /// Call this once at app start
  static Future<void> init() async {
    if (_assetPaths != null) return;

    try {
      final manifest = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifest);
      _assetPaths = manifestMap.keys
          .where((path) => path.startsWith(_basePath))
          .toSet();
      debugPrint('✅ Loaded ${_assetPaths?.length} pantry assets');
    } catch (e) {
      debugPrint('❌ Error loading asset manifest: $e');
      _assetPaths = {};
    }
  }

  static String _normalize(String name) {
    if (name.isEmpty) return '';
    return name
        .toLowerCase()
        .trim()
        .replaceAll("&", "and")
        .replaceAll(RegExp(r"[^\w\s]"), "")
        .replaceAll(RegExp(r"\s+"), "_");
  }

  /// Get image widget for ingredient - uses imageUrl if provided, otherwise uses backend generation
  static Widget getImageWidget(String itemName, {double size = 56, String? imageUrl}) {
    return IngredientImageThumbnail(
      ingredientName: itemName,
      size: size,
      imageUrl: imageUrl, // Pass the imageUrl to the thumbnail widget
    );
  }

  /// Legacy method for static asset paths (kept for compatibility)
  static String getImage(String itemName) {
    if (itemName.isEmpty) {
      debugPrint('❌ Empty item name, using fallback');
      return _getFallbackPath();
    }

    final normalized = _normalize(itemName);
    // First try with temp_ prefix (matching your actual files)
    final tempCandidate = "$_basePath" "temp_$normalized.png";
    debugPrint('🔍 Looking for asset: $tempCandidate');

    if (_assetPaths?.contains(tempCandidate) ?? false) {
      debugPrint('✅ Found asset: $tempCandidate');
      return tempCandidate;
    }

    // If not found, try without the temp_ prefix (for any future images)
    final candidate = "$_basePath$normalized.png";
    debugPrint('🔍 Looking for asset: $candidate');

    if (_assetPaths?.contains(candidate) ?? false) {
      debugPrint('✅ Found asset: $candidate');
      return candidate;
    }

    debugPrint('⚠️  Asset not found, using fallback');
    return _getFallbackPath();
  }

  static String _getFallbackPath() {
    final path = "$_basePath$_fallback";
    debugPrint('🔄 Using fallback image: $path');
    return path;
  }

  /// Get emoji fallback for ingredient name
  static String getEmojiForIngredient(String ingredientName) {
    if (ingredientName.isEmpty) return "🍽️";
    
    final name = ingredientName.toLowerCase().trim();
    
    // Common ingredient emoji mappings
    final Map<String, String> emojiMap = {
      // Vegetables
      'tomato': '🍅',
      'onion': '🧅',
      'garlic': '🧄',
      'potato': '🥔',
      'carrot': '🥕',
      'lettuce': '🥬',
      'cucumber': '🥒',
      'bell pepper': '🫑',
      'pepper': '🫑',
      'corn': '🌽',
      'broccoli': '🥦',
      'mushroom': '🍄',
      'spinach': '🥬',
      'cabbage': '🥬',
      
      // Fruits
      'apple': '🍎',
      'banana': '🍌',
      'orange': '🍊',
      'lemon': '🍋',
      'lime': '🍋',
      'grape': '🍇',
      'strawberry': '🍓',
      'blueberry': '🫐',
      'watermelon': '🍉',
      'pineapple': '🍍',
      'mango': '🥭',
      
      // Dairy
      'milk': '🥛',
      'cheese': '🧀',
      'cream cheese': '🧀',
      'butter': '🧈',
      'cream': '🥛',
      'yogurt': '🥛',
      
      // Meat & Protein
      'chicken': '🍗',
      'beef': '🥩',
      'pork': '🥩',
      'fish': '🐟',
      'salmon': '🐟',
      'egg': '🥚',
      'bacon': '🥓',
      'sausage': '🥓',
      
      // Grains & Carbs
      'bread': '🍞',
      'rice': '🍚',
      'pasta': '🍝',
      'noodles': '🍜',
      'flour': '🌾',
      'oats': '🥣',
      
      // Spices & Seasonings
      'salt': '🧂',
      'pepper': '🧂',
      'sugar': '🍚',
      'granulated sugar': '🍚',
      'honey': '🍯',
      'chili': '🌶️',
      'spice': '🌶️',
      
      // Legumes
      'beans': '🫘',
      'lentils': '🥣',
      'chickpeas': '🫘',
      'dal': '🥣',
      
      // Oils & Liquids
      'oil': '🫒',
      'olive oil': '🫒',
      'vinegar': '🍾',
      'water': '💧',
      
      // Nuts & Seeds
      'nuts': '🥜',
      'almond': '🥜',
      'walnut': '🥜',
      'peanut': '🥜',
      'sesame': '🫘',
      
      // Herbs
      'basil': '🌿',
      'parsley': '🌿',
      'cilantro': '🌿',
      'mint': '🌿',
      'herbs': '🌿',
      
      // Cooking
      'flour': '🌾',
      'baking powder': '🧪',
      'baking soda': '🧪',
      'yeast': '🧪',
      
      // General
      'ingredient': '🍽️',
      'food': '🍽️',
      'recipe': '👨‍🍳',
    };
    
    // Check for exact matches first
    if (emojiMap.containsKey(name)) {
      return emojiMap[name]!;
    }
    
    // Check for partial matches
    for (final entry in emojiMap.entries) {
      if (name.contains(entry.key)) {
        return entry.value;
      }
    }
    
    // Default fallback based on category
    if (name.contains('vegetable') || name.contains('veg')) return '🥬';
    if (name.contains('fruit')) return '🍎';
    if (name.contains('meat') || name.contains('chicken') || name.contains('beef')) return '🥩';
    if (name.contains('fish') || name.contains('seafood')) return '🐟';
    if (name.contains('dairy') || name.contains('milk') || name.contains('cheese')) return '🧀';
    if (name.contains('grain') || name.contains('rice') || name.contains('bread')) return '🌾';
    if (name.contains('spice') || name.contains('herb')) return '🌿';
    
    return '🍽️'; // Default food emoji
  }
}