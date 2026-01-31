import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/item_image_resolver.dart';
import '../../../core/enums/scan_mode.dart';
import '../../../data/services/shopping_list_service.dart';
import '../../../data/services/pantry_add_service.dart';
import '../../../new_service/ingredient_detection_service.dart';
import '../../../data/services/ingredient_metrics_service.dart';
import '../../../data/models/ingredient_model.dart';
import '../../widgets/ingredient_row.dart';
import '../../../state/pantry_state.dart';
import 'pantry_home_screen.dart';
import 'pantry_search_add_screen.dart';
import 'package:lottie/lottie.dart';
import '../../../core/services/auth_service.dart';

enum ReviewState { confirm, scanning, failed }

class PantryReviewIngredientsScreen extends StatefulWidget {
  final XFile capturedImage;
  final ScanMode mode;

  const PantryReviewIngredientsScreen({
    super.key,
    required this.capturedImage,
    this.mode = ScanMode.pantry,
  });

  @override
  State<PantryReviewIngredientsScreen> createState() =>
      _PantryReviewIngredientsScreenState();
}

class _PantryReviewIngredientsScreenState
    extends State<PantryReviewIngredientsScreen> {
  ReviewState _state = ReviewState.confirm;
  final PantryAddService _pantryService = PantryAddService();

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case ReviewState.confirm:
        return _ConfirmPhotoView(
          capturedImage: widget.capturedImage,
          onLooksGood: () async {
            final uiStartTime = DateTime.now();
            debugPrint(" [UI] Starting scan at: ${uiStartTime.millisecondsSinceEpoch}");
            setState(() => _state = ReviewState.scanning);

            try {
              final response = await IngredientDetectionService().detectIngredients(widget.capturedImage!);
              final result = response['data'];

              final uiEndTime = DateTime.now();
              debugPrint(" [UI] Scan result received at: ${uiEndTime.millisecondsSinceEpoch}");
              debugPrint(" [UI] UI scan time: ${uiEndTime.difference(uiStartTime).inMilliseconds}ms");
              debugPrint(" [UI] Result received instantly, processing...");

              if (!mounted) return;

              if (widget.mode == ScanMode.pantry) {
                // PANTRY FLOW - Process and route to pantry review
                debugPrint(" [UI] PANTRY MODE - Raw scan result: $result");

                // Check if scan result has ingredients data directly
                if (response['ok'] == true && response.containsKey('data')) {
                  final data = response['data'];
                  final ingredients = data['ingredients'];
                  if (ingredients is List && ingredients.isNotEmpty) {
                    debugPrint(" [UI] PANTRY MODE - Direct ingredients found: $ingredients");

                    // Convert new API structure to expected format
                    final convertedIngredients = ingredients.map((item) => {
                      "item": item["name"] ?? "Unknown",
                      "quantity": item["qty"] ?? 1,
                      "unit": item["apx_unit"] ?? "pcs",
                      "imageURL": item["image_url"] ?? "",
                      "match%": ((item["confidence"] ?? 1.0) * 100).toInt(),
                    }).toList();

                    debugPrint(" [UI] Ingredients converted, navigating to review screen...");
                    
                    if (!mounted) return;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _ScannedIngredientsListScreen(
                          items: convertedIngredients,
                        ),
                      ),
                    ).then((result) {
                      // Check if items were added successfully
                      if (result == true) {
                        if (mounted) {
                          Navigator.pop(context, true);
                        }
                        return;
                      }
                      
                      // Otherwise reset to confirm state (user cancelled/backed out)
                      if (mounted) {
                        setState(() => _state = ReviewState.confirm);
                      }
                    });
                    return;
                  }
                }

                // Fallback (though unlikely with new API)
                if (!mounted) return;
                setState(() => _state = ReviewState.failed);
              }
            } catch (scanError) {
              debugPrint('General scanning error: $scanError');
              if (!mounted) return;
              setState(() => _state = ReviewState.failed);
            }
          },
          onRetake: () => Navigator.pop(context),
        );

      case ReviewState.scanning:
        return _ScanningView(
          capturedImage: widget.capturedImage,
          onFail: () => setState(() => _state = ReviewState.failed),
        );

      case ReviewState.failed:
        return const _UploadFailedView();
    }
  }
}

///// 1️⃣ Confirm Screen UI
class _ConfirmPhotoView extends StatelessWidget {
  final XFile capturedImage;
  final VoidCallback onLooksGood;
  final VoidCallback onRetake;

  const _ConfirmPhotoView({
    required this.capturedImage,
    required this.onLooksGood,
    required this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back Button at top
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, size: 20),
                  onPressed: onRetake,
                ),
              ),
            ),

            // Vertical rectangular image preview
            Expanded(
              flex: 4,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.0),
                  child: Image.file(
                    File(capturedImage.path),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
            ),

            // Text content below image
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                "Great! Is the photo clear enough to see ingredients?",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Bottom action buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 26),
                      onPressed: onRetake,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF7A4A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 2,
                        ),
                        onPressed: onLooksGood,
                        child: const Text(
                          "Yes, Looks Good",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

///// 2️⃣ Scanning UI (ANIMATED – LOTTIE)
class _ScanningView extends StatelessWidget {
  final XFile? capturedImage;
  final VoidCallback onFail;

  const _ScanningView({
    this.capturedImage,
    required this.onFail,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Responsive sizing based on screen dimensions
    final animationSize = screenWidth * 0.65; // 65% of screen width
    final titleFontSize = screenWidth * 0.04; // Responsive title font
    final descriptionFontSize = screenWidth * 0.032; // Responsive description font
    final bottomTextFontSize = screenWidth * 0.028; // Responsive bottom text font
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.06, // 6% of screen width
            vertical: screenHeight * 0.02, // 2% of screen height
          ),
          child: Column(
            children: [
              // Top spacing
              SizedBox(height: screenHeight * 0.08),
              
              // 🔄 Vegetable Scan Animation
              Expanded(
                flex: 3,
                child: Center(
                  child: Lottie.asset(
                    'assets/Vegetable_Scan.json',
                    width: animationSize,
                    height: animationSize,
                    repeat: true,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.03),

              // Title
              Text(
                'Hang tight',
                style: TextStyle(
                  fontSize: titleFontSize.clamp(18.0, 24.0), // Min 18, Max 24
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),

              SizedBox(height: screenHeight * 0.02),

              // Description
              Text(
                "We're scanning your invoice\nfor all the yummy goodies...",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: descriptionFontSize.clamp(14.0, 16.0), // Min 14, Max 16
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),

              const Spacer(flex: 2),

              // Bottom text with proper spacing
              Padding(
                padding: EdgeInsets.only(
                  bottom: screenHeight * 0.08, // Responsive bottom padding
                ),
                child: Text(
                  "Just a few more seconds and\nyour pantry will be up to date.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: bottomTextFontSize.clamp(12.0, 14.0), // Min 12, Max 14
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

///// 3️⃣ Failed UI Sheet
class _UploadFailedView extends StatelessWidget {
  const _UploadFailedView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.85),

      body: Stack(
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 32),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),

              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Upload Failed!",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      "Oops! Something went wrong.\nTry Uploading image again!",
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: Colors.grey.shade600,
                      ),
                    ),

                    const SizedBox(height: 26),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: const Color(0xFFFF7A4A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          "Retry Upload",
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanningFrame extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cornerLength = 40.0;
    const stroke = 3.0;
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw four L-shaped corners at the edges of the screen
    // Top-left
    canvas.drawLine(Offset(0, 0), Offset(cornerLength, 0), paint);
    canvas.drawLine(Offset(0, 0), Offset(0, cornerLength), paint);

    // Top-right
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - cornerLength, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerLength), paint);

    // Bottom-left
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - cornerLength), paint);
    canvas.drawLine(Offset(0, size.height), Offset(cornerLength, size.height), paint);

    // Bottom-right
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - cornerLength), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - cornerLength, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Screen to display list of scanned ingredients with review UI
class _ScannedIngredientsListScreen extends StatefulWidget {
  final List<Map<String, dynamic>> items;

  const _ScannedIngredientsListScreen({
    super.key,
    required this.items,
  });

  @override
  State<_ScannedIngredientsListScreen> createState() => _ScannedIngredientsListScreenState();
}

class _ScannedIngredientsListScreenState extends State<_ScannedIngredientsListScreen> {
  List<IngredientModel> _ingredients = [];
  final PantryAddService _pantryService = PantryAddService();

  /// 👉 Store price, quantity & metrics separately (clean approach)
  final Map<String, double> _priceMap = {};
  final Map<String, double> _quantityMap = {};
  final Map<String, String> _imageMap = {}; // Store image URLs

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final screenStartTime = DateTime.now();
    debugPrint("🎯 [ReviewScreen] Screen init started at: ${screenStartTime.millisecondsSinceEpoch}");

    // Skip metrics loading for development speed
    _fetchIngredients();

    final screenEndTime = DateTime.now();
    debugPrint("🎯 [ReviewScreen] Screen init completed at: ${screenEndTime.millisecondsSinceEpoch}");
    debugPrint("⏱️ [ReviewScreen] Init time: ${screenEndTime.difference(screenStartTime).inMilliseconds}ms");
  }

  Future<void> _loadMetricsAndFetchIngredients() async {
    await IngredientMetricsService().loadMetrics();
    _fetchIngredients();
  }

  // ---------------- Fetch Ingredients from Scan ----------------
  Future<void> _fetchIngredients() async {
    final fetchStartTime = DateTime.now();
    debugPrint("🎯 [ReviewScreen] Starting ingredient fetch at: ${fetchStartTime.millisecondsSinceEpoch}");

    try {
      final ing = widget.items;
      debugPrint("🎯 [ReviewScreen] Processing ${ing.length} ingredients");

      _ingredients = ing.map<IngredientModel>((item) {
        final id = DateTime.now().microsecondsSinceEpoch.toString();

        _priceMap[id] = double.tryParse(item["price"]?.toString() ?? "0") ?? 0.0;
        _quantityMap[id] = double.tryParse(item["quantity"]?.toString() ?? "1.0") ?? 1.0;
        _imageMap[id] = item["imageURL"]?.toString() ?? item["image_url"]?.toString() ?? ""; // Store image URL
        debugPrint("🎯 [ReviewScreen] Item keys for ${item["item"]}: ${item.keys.toList()}");
        debugPrint("🎯 [ReviewScreen] Image mapping for ${item["item"]}: ${_imageMap[id]}");

        // Use match percentage from backend if available, default to 100
        final matchPercent = int.tryParse(item["match"]?.toString() ?? item["match%"]?.toString() ?? "100") ?? 100;

        return IngredientModel(
          id: id,
          emoji: ItemImageResolver.getEmojiForIngredient(item["item"]?.toString() ?? ""),
          name: item["item"]?.toString() ?? "",
          match: matchPercent,
        );
      }).toList();

      final fetchEndTime = DateTime.now();
      debugPrint("🎯 [ReviewScreen] Ingredient fetch completed at: ${fetchEndTime.millisecondsSinceEpoch}");
      debugPrint("⏱️ [ReviewScreen] Fetch time: ${fetchEndTime.difference(fetchStartTime).inMilliseconds}ms");

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint("❌ [ReviewScreen] Fetch failed: $e");
      setState(() {
        _error = "Failed: $e";
        _isLoading = false;
      });
    }
  }

  // =====================================================
  // ADD INGREDIENT (NAME + METRIC + QUANTITY)
  // =====================================================
  Future<void> _showAddIngredientDialog() async {
    final nameController = TextEditingController();
    final metricController = TextEditingController();
    final quantityController = TextEditingController(text: "1.0");

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Ingredient"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration:
                  const InputDecoration(labelText: "Ingredient name"),
            ),
            TextField(
              controller: metricController,
              decoration: const InputDecoration(labelText: "Metric"),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 16),
            const Text("Quantity", style: TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            StatefulBuilder(
              builder: (context, setDialogState) {
                double qty = double.tryParse(quantityController.text) ?? 1.0;
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFF7A4A)),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, color: Color(0xFFFF7A4A)),
                        onPressed: () {
                          if (qty > 0.5) {
                            qty -= 0.5;
                            quantityController.text = qty.toStringAsFixed(1);
                            setDialogState(() {});
                          }
                        },
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            qty.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: Color(0xFFFF7A4A)),
                        onPressed: () {
                          qty += 0.5;
                          quantityController.text = qty.toStringAsFixed(1);
                          setDialogState(() {});
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final id = DateTime.now().microsecondsSinceEpoch.toString();
                setState(() {
                  _ingredients.add(IngredientModel(
                    id: id,
                    emoji: ItemImageResolver.getEmojiForIngredient(nameController.text),
                    name: nameController.text,
                    match: 100,
                  ));
                  _priceMap[id] = 0.0; // Price not used in pantry
                  _quantityMap[id] = double.tryParse(quantityController.text) ?? 1.0;
                });
              }
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // EDIT INGREDIENT
  // =====================================================
  Future<void> _editIngredient(IngredientModel ingredient) async {
    final nameController = TextEditingController(text: ingredient.name);
    final metricController = TextEditingController(
        text: "");
    final quantityController = TextEditingController(
        text: _quantityMap[ingredient.id]?.toStringAsFixed(1) ?? "1.0");

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Ingredient"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration:
                  const InputDecoration(labelText: "Ingredient name"),
            ),
            TextField(
              controller: metricController,
              decoration: const InputDecoration(labelText: "Metric"),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 16),
            const Text("Quantity", style: TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            StatefulBuilder(
              builder: (context, setDialogState) {
                double qty = double.tryParse(quantityController.text) ?? 1.0;
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFF7A4A)),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, color: Color(0xFFFF7A4A)),
                        onPressed: () {
                          if (qty > 0.5) {
                            qty -= 0.5;
                            quantityController.text = qty.toStringAsFixed(1);
                            setDialogState(() {});
                          }
                        },
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            qty.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: Color(0xFFFF7A4A)),
                        onPressed: () {
                          qty += 0.5;
                          quantityController.text = qty.toStringAsFixed(1);
                          setDialogState(() {});
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                setState(() {
                  // Update ingredient
                  final index = _ingredients.indexWhere((i) => i.id == ingredient.id);
                  if (index != -1) {
                    _ingredients[index] = IngredientModel(
                      id: ingredient.id,
                      emoji: ItemImageResolver.getEmojiForIngredient(nameController.text),
                      name: nameController.text,
                      match: ingredient.match,
                    );
                    _priceMap[ingredient.id!] = 0.0; // Price not used in pantry
                    _quantityMap[ingredient.id!] = double.tryParse(quantityController.text) ?? 1.0;
                  }
                });
              }
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // REMOVE INGREDIENT
  // =====================================================
  void _removeIngredient(String id) {
    setState(() {
      _ingredients.removeWhere((i) => i.id == id);
      _priceMap.remove(id);
      _quantityMap.remove(id);
      _imageMap.remove(id); // Remove image URL
    });
  }

  // =====================================================
  // BUILD UI
  // =====================================================
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Text(_error!),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(18, 40, 18, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: _circleIcon(Icons.arrow_back),
                  ),
                  GestureDetector(
                    onTap: _showAddIngredientDialog,
                    child: _addMoreBtn(),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Text(
                'Review Ingredients',
                style:
                    TextStyle(fontWeight: FontWeight.w900, fontSize: 28),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              itemCount: _ingredients.length,
              itemBuilder: (context, index) {
                final ingredient = _ingredients[index];
                final quantity = _quantityMap[ingredient.id] ?? 1;

                return IngredientRow(
                  emoji: ingredient.emoji,
                  name: ingredient.name,
                  matchPercent: ingredient.match,
                  quantity: quantity,
                  onRemove: () => _removeIngredient(ingredient.id!),
                  onEdit: () => _editIngredient(ingredient),
                  imageUrl: _imageMap[ingredient.id], // Pass image URL
                );
              },
            ),
          ),
          
          // Add to Pantry button at bottom
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 12,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: GestureDetector(
              onTap: () async {
                try {
                  // Show loading indicator
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: CircularProgressIndicator(color: Color(0xFFFF7A4A)),
                    ),
                  );

                  // Prepare items for pantry service
                  final pantryItems = _ingredients.map((ingredient) {
                    return {
                      'name': ingredient.name,
                      'quantity': (_quantityMap[ingredient.id] ?? 1).toDouble(),
                      'unit': 'pcs',
                      'imageUrl': _imageMap[ingredient.id], // Include imageUrl
                    };
                  }).toList();

                  // Always update local state
                  final pantryState = Provider.of<PantryState>(context, listen: false);
                  final shoppingListService = Provider.of<ShoppingListService>(context, listen: false);
                  
                  int duplicateCount = 0;
                  int addedCount = 0;
                  
                  // Add each item to local pantry state with duplicate check
                  for (var item in pantryItems) {
                    final itemName = item['name'] as String;
                    
                    // Check if item already exists in pantry
                    final existingItem = pantryState.pantryItems.firstWhere(
                      (pantryItem) => pantryItem.name.toLowerCase() == itemName.toLowerCase(),
                      orElse: () => PantryItem(name: '', quantity: 0, unit: ''),
                    );
                    
                    if (existingItem.name.isNotEmpty) {
                      // Item already exists, update quantity instead of adding duplicate
                      await pantryState.setItem(
                        itemName,
                        existingItem.quantity + (item['quantity'] as double),
                        item['unit'] as String,
                        imageUrl: item['imageUrl'] as String?, // Pass imageUrl for duplicates too
                      );
                      duplicateCount++;
                    } else {
                      // New item, add to pantry
                      await pantryState.setItem(
                        itemName,
                        item['quantity'] as double,
                        item['unit'] as String,
                        imageUrl: item['imageUrl'] as String?, // Pass imageUrl for new items too
                      );
                      addedCount++;
                    }
                  }

                  // Save items to remote server using the correct API format
                  debugPrint("📤 [PantryReview] Saving ${pantryItems.length} items to remote server...");
                  final authService = Provider.of<AuthService>(context, listen: false);
                  final String? userId = authService.user?.mobile_no;
                  final serverResponse = await _pantryService.addIndividualPantryItems(pantryItems, userId: userId);
                  debugPrint("✅ [PantryReview] Server save result: $serverResponse");
                  
                  // Comprehensive verification using response IDs
                  bool isServerVerified = false;
                  if (serverResponse['status'] == true && serverResponse['added_items'] != null) {
                    final addedItems = serverResponse['added_items'] as List;
                    if (addedItems.isNotEmpty) {
                      // Check if items have IDs as requested by user
                      final hasIds = addedItems.any((item) => item['_id'] != null);
                      if (hasIds) {
                        isServerVerified = true;
                        debugPrint("🔍 [PantryReview] Server success verified with ${addedItems.length} items (IDs present)");
                      }
                    }
                  }

                  if (!isServerVerified) {
                    debugPrint("⚠️ [PantryReview] Server verification failed or IDs missing, though status might be true");
                  }
                  
                  String message;
                  if (addedCount > 0 && duplicateCount > 0) {
                    message = 'Added $addedCount new items, updated $duplicateCount duplicates';
                  } else if (duplicateCount > 0) {
                    message = 'Updated $duplicateCount existing items';
                  } else if (addedCount > 0) {
                    message = 'Added $addedCount new items';
                  } else {
                    message = 'No items were added';
                  }
                  
                  // 🔄 Refresh pantry list from server
                  await pantryState.syncFromRemote(userId);

                  // Close loading indicator
                  if (mounted) {
                    Navigator.pop(context); // Close loading dialog
                    
                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(message),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                    
                    // Return success to the previous screen (IngredientEntryScreen)
                    Navigator.pop(context, true);
                  }
                } catch (error) {
                  debugPrint('Error adding to pantry: $error');
                  
                  // Close loading indicator
                  if (mounted) {
                    Navigator.pop(context); // Close loading dialog
                    
                    // Show error message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to add items to pantry'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }
                }
              },
              child: Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7A4A),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF7A4A).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Add to Pantry',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleIcon(IconData icon) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Icon(icon, size: 20),
    );
  }

  Widget _addMoreBtn() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFFF7A4A),
      ),
      child: const Icon(
        Icons.add,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}