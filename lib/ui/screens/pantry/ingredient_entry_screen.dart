import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'pantry_review_ingredients_screen.dart';
import '../../data/services/pantry_add_service.dart';
import '../../core/services/auth_service.dart';
import 'package:provider/provider.dart';

class IngredientEntryScreen extends StatefulWidget {
  final Function? onItemsAdded;
  
  const IngredientEntryScreen({
    super.key,
    this.onItemsAdded,
  });

  @override
  State<IngredientEntryScreen> createState() => _IngredientEntryScreenState();
}

class _IngredientEntryScreenState extends State<IngredientEntryScreen> {
  final ImagePicker _picker = ImagePicker();
  final PantryAddService _pantryService = PantryAddService();
  bool _isLoading = false;

  Future<void> _pickImage() async {
    try {
      // Show immediate feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text('Opening camera...'),
              ],
            ),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.black87,
          ),
        );
      }

      // Request camera permission first
      final cameraPermission = await Permission.camera.request();
      
      if (cameraPermission.isDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Camera permission is required to take photos'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      if (cameraPermission.isPermanentlyDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Camera Permission Required'),
              content: const Text('Please enable camera permission in app settings to use this feature.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    openAppSettings();
                  },
                  child: const Text('Settings'),
                ),
              ],
            ),
          );
        }
        return;
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      
      // Clear feedback snackbar
      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      if (image != null) {
        await _processImage(image);
      }
    } catch (e) {
      // Clear feedback snackbar
      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      debugPrint("Error picking image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _processImage(XFile image) async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      final addedItems = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PantryReviewIngredientsScreen(capturedImage: image),
        ),
      );

      if (addedItems == true) {
        // Items were already saved in the review screen
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Items added to pantry'), backgroundColor: Colors.green),
           );
           widget.onItemsAdded?.call();
           Navigator.pop(context, true);
        }
        return;
      }

      if (addedItems != null && addedItems is List && addedItems.isNotEmpty) {
        // Save to pantry (Legacy/Fallback flow)
        final authService = Provider.of<AuthService>(context, listen: false);
        final String? userId = authService.user?.mobile_no;
        final success = await _pantryService.saveToPantry(addedItems, userId: userId);
        
        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Items added to pantry')),
            );
            widget.onItemsAdded?.call();
            if (mounted) Navigator.pop(context, addedItems);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to save items')),
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Error processing image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to process image')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add to Pantry'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.photo_camera,
                    size: 80,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Take a photo of your receipt',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32.0, vertical: 8.0),
                    child: Text(
                      'Make sure the receipt is well-lit and all items are clearly visible',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_camera),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
                      child: Text('TAKE PHOTO', style: TextStyle(fontSize: 16)),
                    ),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
