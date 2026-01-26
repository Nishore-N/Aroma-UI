// Update the imports at the top
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'capture_preview_screen.dart';
import 'review_ingredients_screen.dart';
import '../../../core/enums/scan_mode.dart';
import '../pantry/review_items_screen.dart';
import '../pantry/pantry_review_ingredients_screen.dart';
import '../../../data/services/scan_bill_service.dart';
import '../../../data/services/pantry_add_service.dart';

class IngredientEntryScreen extends StatelessWidget {
  final ScanMode mode;
  
  const IngredientEntryScreen({
    super.key,
    required this.mode,
  });

  Future<void> _handleGallerySelection(BuildContext context) async {
  final ImagePicker picker = ImagePicker();
  final XFile? image = await picker.pickImage(
    source: ImageSource.gallery,
    maxWidth: 1200,
    maxHeight: 1600,
    imageQuality: 85,
  );
  
  if (image == null || !context.mounted) return;

  if (mode == ScanMode.cooking) {
    // Navigate directly to ReviewIngredientsScreen without scanning first
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ReviewIngredientsScreen(
            capturedImage: image,
            mode: mode,
            // Don't pass scanResult yet, it will be loaded when confirmed
          ),
        ),
      );
    }
  } else {
    // For pantry, navigate to PantryReviewIngredientsScreen to show "Looks Good" screen
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PantryReviewIngredientsScreen(
            capturedImage: image,
          ),
        ),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade300,
      body: Stack(
        children: [
          /// --- Background ---
          Positioned.fill(
            child: Container(color: Colors.grey.shade300),
          ),

          /// --- Close Button ---
          Align(
            alignment: const Alignment(0, 0.2),
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),

          /// --- Bottom Sheet ---
          Align(
            alignment: Alignment.bottomCenter,
            child: Stack(
              children: [
                SvgPicture.asset(
                  'assets/images/recipes/white_outer_card.svg',
                  width: MediaQuery.of(context).size.width,
                  fit: BoxFit.fill,
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(26, 22, 26, 42),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        /// Title
                        Text(
                          mode == ScanMode.cooking
                              ? 'Start Adding Ingredients'
                              : 'Add Items to Pantry',
                          style: AppTypography.h3.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),

                        const SizedBox(height: 26),

                        /// --- Action Icons ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _OptionCard(
                              label: 'Search',
                              icon: Icons.search_rounded,
                              onTap: () {
                                // TODO: Implement search functionality
                              },
                            ),
                            _OptionCard(
                              label: 'Camera',
                              icon: Icons.camera_alt_rounded,
                              onTap: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => CapturePreviewScreen(
                                    mode: mode,
                                  ),
                                ));
                              },
                            ),
                            _OptionCard(
                              label: 'Gallery',
                              icon: Icons.photo_library_rounded,
                              onTap: () => _handleGallerySelection(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Keep the existing _OptionCard widget

/// -------- Option Cards --------
class _OptionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _OptionCard({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              icon,
              size: 34,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTypography.body2.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}