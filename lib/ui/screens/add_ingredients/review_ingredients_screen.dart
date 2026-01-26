import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/enums/scan_mode.dart';
import '../../../widgets/primary_button.dart';
import 'review_ingredients_list_screen.dart';
import '../../../data/services/scan_bill_service.dart';
import '../../../data/services/pantry_add_service.dart';
import '../pantry/review_items_screen.dart';

import 'package:lottie/lottie.dart';

enum ReviewState { confirm, scanning, failed }

class ReviewIngredientsScreen extends StatefulWidget {
  final XFile? capturedImage;
  final Map<String, dynamic>? scanResult;
  final ScanMode mode;

  const ReviewIngredientsScreen({
    super.key,
    required this.capturedImage,
    this.scanResult,
    this.mode = ScanMode.cooking,
  });

  

  @override
  State<ReviewIngredientsScreen> createState() =>
      _ReviewIngredientsScreenState();
}

class _ReviewIngredientsScreenState extends State<ReviewIngredientsScreen> {
  ReviewState _state = ReviewState.confirm;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_state == ReviewState.scanning) {
          setState(() => _state = ReviewState.confirm);
        }
        return true;
      },
      child: switch (_state) {
        ReviewState.confirm => _ConfirmPhotoView(
          capturedImage: widget.capturedImage,

          onLooksGood: () async {
            setState(() => _state = ReviewState.scanning);

            try {
              final result = await ScanBillService().scanBill(widget.capturedImage!);

              if (!mounted) return;

              if (widget.mode == ScanMode.pantry) {
                // PANTRY FLOW - Process and route to pantry review
                debugPrint(" PANTRY MODE - Raw scan result: $result");
                
                // Check if scan result has ingredients data directly from new API
                if (result.containsKey("ingredients_with_quantity")) {
                  final ingredients = result["ingredients_with_quantity"];
                  if (ingredients is List && ingredients.isNotEmpty) {
                    debugPrint(" PANTRY MODE - Direct ingredients found: $ingredients");
                    
                    // Convert new API structure to expected format with nutritional data
                    final convertedIngredients = ingredients.map((item) => {
                      "item": item["item"] ?? "Unknown",
                      "quantity": item["quantity"] ?? 1,
                      "unit": item["unit"] ?? "pcs",
                      "imageURL": item["imageURL"] ?? "",
                      "match%": item["match%"] ?? 100,
                      "macros": item["macros"] ?? {},
                      "calories": item["macros"]?["calories_kcal"] ?? 0,
                      "protein": item["macros"]?["protein_g"] ?? 0,
                      "carbs": item["macros"]?["carbohydrates_g"] ?? 0,
                      "fat": item["macros"]?["fat_g"] ?? 0,
                    }).toList();
                    
                    if (!mounted) return;
                    
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReviewItemsScreen(
                          items: convertedIngredients,
                        ),
                      ),
                    );
                    return;
                  }
                }
                
                final rawText = result["raw_text"];
                debugPrint(" PANTRY MODE - Raw text: $rawText");
                
                try {
                  final pantryResult = await PantryAddService().processRawText(rawText);
                  debugPrint(" PANTRY MODE - Pantry result: $pantryResult");
                  
                  final items = pantryResult["ingredients_with_quantity"];
                  debugPrint(" PANTRY MODE - Items extracted: $items");

                  if (!mounted) return;
                  
                  if (items != null && items.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReviewItemsScreen(
                          items: List<Map<String, dynamic>>.from(items),
                        ),
                      ),
                    );
                  } else {
                    // Fallback: Try to extract ingredients directly from scan result
                    try {
                      final List<Map<String, dynamic>> fallbackItems = [];
                      
                      // Check if scan result has ingredients data directly
                      if (result.containsKey("ingredients_with_quantity")) {
                        final ingredients = result["ingredients_with_quantity"];
                        if (ingredients is List) {
                          for (var item in ingredients) {
                            if (item is Map && item.containsKey("item")) {
                              fallbackItems.add({
                                "item": item["item"] ?? "Unknown",
                                "quantity": item["quantity"] ?? 1,
                                "unit": item["unit"] ?? "pcs",
                                "imageURL": item["imageURL"] ?? "",
                                "match%": item["match%"] ?? 100,
                                "macros": item["macros"] ?? {},
                                "calories": item["macros"]?["calories_kcal"] ?? 0,
                                "protein": item["macros"]?["protein_g"] ?? 0,
                                "carbs": item["macros"]?["carbohydrates_g"] ?? 0,
                                "fat": item["macros"]?["fat_g"] ?? 0,
                              });
                            }
                          }
                        }
                      }
                      
                      debugPrint(" PANTRY MODE - Fallback items: $fallbackItems");
                      
                      if (fallbackItems.isNotEmpty && mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReviewItemsScreen(
                              items: fallbackItems,
                            ),
                          ),
                        );
                      } else {
                        if (!mounted) return;
                        setState(() => _state = ReviewState.failed);
                      }
                    } catch (fallbackError) {
                      debugPrint(" PANTRY MODE - Fallback also failed: $fallbackError");
                      if (!mounted) return;
                      setState(() => _state = ReviewState.failed);
                    }
                  }
                } catch (e) {
                  debugPrint(" PANTRY MODE - Processing error: $e");
                  
                  // Fallback: Try to extract ingredients directly from scan result
                  try {
                    final List<Map<String, dynamic>> fallbackItems = [];
                    
                    // Check if scan result has ingredients data directly
                    if (result.containsKey("ingredients_with_quantity")) {
                      final ingredients = result["ingredients_with_quantity"];
                      if (ingredients is List) {
                        for (var item in ingredients) {
                          if (item is Map && item.containsKey("item")) {
                            fallbackItems.add({
                              "item": item["item"] ?? "Unknown",
                              "quantity": item["quantity"] ?? 1,
                              "unit": item["unit"] ?? "pcs",
                              "imageURL": item["imageURL"] ?? "",
                              "match%": item["match%"] ?? 100,
                              "macros": item["macros"] ?? {},
                              "calories": item["macros"]?["calories_kcal"] ?? 0,
                              "protein": item["macros"]?["protein_g"] ?? 0,
                              "carbs": item["macros"]?["carbohydrates_g"] ?? 0,
                              "fat": item["macros"]?["fat_g"] ?? 0,
                            });
                          }
                        }
                      }
                    }
                    
                    debugPrint(" PANTRY MODE - Fallback items: $fallbackItems");
                    
                    if (fallbackItems.isNotEmpty && mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReviewItemsScreen(
                            items: fallbackItems,
                          ),
                        ),
                      );
                    } else {
                      if (!mounted) return;
                      setState(() => _state = ReviewState.failed);
                    }
                  } catch (fallbackError) {
                    debugPrint(" PANTRY MODE - Fallback also failed: $fallbackError");
                    if (!mounted) return;
                    setState(() => _state = ReviewState.failed);
                  }
                }
              } else {
                debugPrint("🎯 [NORMAL MODE] Raw scan result: $result");
                debugPrint("🎯 [NORMAL MODE] Result keys: ${result.keys.toList()}");
                
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReviewIngredientsListScreen(scanResult: result),
                  ),
                ).then((_) {
                  // When coming back from review screen, reset to confirm state
                  if (mounted) {
                    setState(() => _state = ReviewState.confirm);
                  }
                });
              }
            } catch (e) {
              setState(() => _state = ReviewState.failed);
            }
          },

          onRetake: () => Navigator.pop(context),
        ),

        ReviewState.scanning => _ScanningView(
          capturedImage: widget.capturedImage,
          onFail: () => setState(() => _state = ReviewState.failed),
        ),

        ReviewState.failed => const _UploadFailedView(),
      },
    );
  }
}

///// 1️⃣ Confirm Screen UI
class _ConfirmPhotoView extends StatelessWidget {
  final XFile? capturedImage;
  final VoidCallback onLooksGood;
  final VoidCallback onRetake;

  const _ConfirmPhotoView({
    this.capturedImage,
    required this.onLooksGood,
    required this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    const double horizontalPadding = 0.0; // Remove horizontal padding for full width
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back Button at the top
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
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),

            // Vertical rectangular image preview - more rectangular
            Expanded(
              flex: 4,  // Increased flex to make it take more vertical space
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
                  child: capturedImage != null
                      ? kIsWeb
                          ? CachedNetworkImage(
                              imageUrl: capturedImage!.path,
                              fit: BoxFit.cover,
                              height: double.infinity,
                              width: double.infinity,
                              placeholder: (context, url) => _plainFallbackImage(),
                              errorWidget: (context, url, error) => _plainFallbackImage(),
                            )
                          : Image.file(
                              File(capturedImage!.path),
                              fit: BoxFit.cover,
                              height: double.infinity,
                              width: double.infinity,
                            )
                      : _plainFallbackImage(),
                ),
              ),
            ),

            // Text content below the image
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                "Great! Is the photo clear enough to see the ingredients?",
                style: AppTypography.h3.copyWith(
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
                  GestureDetector(
                    onTap: onRetake,
                    child: SvgPicture.string(
                      '''<svg width="56" height="56" viewBox="0 0 56 56" fill="none" xmlns="http://www.w3.org/2000/svg">
<rect x="0.5" y="0.5" width="55" height="55" rx="15.5" fill="white" stroke="#D9D9D9"/>
<path d="M36.2812 29.5469C36.8906 29.7344 37.2188 30.3438 37.0781 30.9531C35.7656 35.4062 31.6406 38.5 27 38.5C23.25 38.5 19.8281 36.4844 18 33.3438V38.125C18 38.7812 17.4844 39.25 16.875 39.25C16.2188 39.25 15.75 38.7812 15.75 38.125V30.625C15.75 30.0156 16.2188 29.5 16.875 29.5H24.375C24.9844 29.5 25.5 30.0156 25.5 30.625C25.5 31.2812 24.9844 31.75 24.375 31.75H19.6406C21.0469 34.4688 23.8594 36.25 27 36.25C30.6094 36.25 33.8906 33.8125 34.9219 30.3438C35.0625 29.7344 35.7188 29.4062 36.2812 29.5469ZM37.125 16.75C37.7344 16.75 38.25 17.2656 38.25 17.875V25.375C38.25 26.0312 37.7344 26.5 37.125 26.5H29.625C28.9688 26.5 28.5 26.0312 28.5 25.375C28.5 24.7656 28.9688 24.25 29.625 24.25H34.3125C32.9062 21.5781 30.0938 19.75 27 19.75C23.3438 19.75 20.0625 22.2344 19.0781 25.7031C18.8906 26.3125 18.2812 26.6406 17.6719 26.5C17.0625 26.3125 16.7344 25.7031 16.875 25.0938C18.1875 20.6406 22.3594 17.5 27 17.5C30.7031 17.5 34.125 19.5625 36 22.7031V17.875C36 17.2656 36.4688 16.75 37.125 16.75Z" fill="#0D0D0D"/>
</svg>''',
                      width: 56,
                      height: 56,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
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

  // plain fallback image (no AspectRatio) — used inside an outer AspectRatio/SizedBox
  Widget _plainFallbackImage() {
    return Image.asset(
      AssetPaths.vegBoard,
      fit: BoxFit.cover,
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
                          backgroundColor: AppColors.primary,
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