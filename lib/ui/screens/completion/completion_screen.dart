//lib/ui/screens/completion/completion_screen.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';

class CompletionScreen extends StatefulWidget {
  const CompletionScreen({super.key});

  @override
  State<CompletionScreen> createState() => _CompletionScreenState();
}

class _CompletionScreenState extends State<CompletionScreen> {
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  File? _pickedImage;
  Uint8List? _webImage;

  String get _ratingText {
    switch (_rating) {
      case 1:
        return "Poor";
      case 2:
        return "Average";
      case 3:
        return "Good";
      case 4:
        return "Good! Food is Great";
      case 5:
        return "Excellent! Loved it";
      default:
        return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFF7A4D),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),

            /// CHEF IMAGE - Using a placeholder icon since the image is missing
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emoji_food_beverage,
                size: 60,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 14),

            /// TITLE
            const Text(
              "Awesome Chef!",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 6),

            /// SUBTITLE
            const Text(
              "You've successfully completed\nCooking Authentic North Indian Dal Makhani",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 26),

            /// WHITE CARD
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      /// RATING TITLE (CENTERED)
                      const Text(
                        "How do you like the Recipe?",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 14),

                      /// STAR RATING (CENTERED)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return IconButton(
                            splashRadius: 20,
                            icon: Icon(
                              Icons.star,
                              size: 32,
                              color: index < _rating
                                  ? const Color(0xFFFFC107)
                                  : Colors.grey.shade300,
                            ),
                            onPressed: () {
                              setState(() {
                                _rating = index + 1;
                              });
                            },
                          );
                        }),
                      ),

                      if (_rating > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _ratingText,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),

                      const SizedBox(height: 32),

                      /// SHARE TITLE (CENTERED)
                      const Text(
                        "Share your Creation",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 8),

                      /// SHARE DESCRIPTION (CENTERED)
                      const Text(
                        "Share your thoughts & Take a photo of\nyour dish and share it with your\ncommunity",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Colors.black54,
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// COMMENT BOX (FULL WIDTH BUT CENTERED SECTION)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1.4,
                          ),
                        ),
                        child: TextField(
                          controller: _commentController,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            hintText: "your comments",
                            border: InputBorder.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Selected Image Preview with remove button
                      if (_pickedImage != null || _webImage != null)
                        Stack(
                          alignment: Alignment.topRight,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: kIsWeb && _webImage != null
                                    ? Image.memory(
                                        _webImage!,
                                        width: 150,
                                        height: 150,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.file(
                                        _pickedImage!,
                                        width: 150,
                                        height: 150,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 8, right: 8),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.white, size: 18),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  setState(() {
                                    _pickedImage = null;
                                    _webImage = null;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),

                      /// ADD PHOTO BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFFFFEEE8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _pickImage,
                          icon: const Icon(
                            Icons.photo_library,
                            color: Color(0xFFFF7A4D),
                          ),
                          label: Text(
                            _pickedImage == null && _webImage == null ? "Add Photo" : "Change Photo",
                            style: const TextStyle(
                              color: Color(0xFFFF7A4D),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      /// SUBMIT BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF7A4D),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {},
                          child: const Text(
                            "Submit",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      // Skip permission check on web
      if (!kIsWeb) {
        // Request storage permission only for mobile
        final status = await Permission.photos.request();
        
        if (status.isDenied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Storage permission is required to select images')),
            );
          }
          return;
        }
      }

      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        // For web, we need to handle the path differently
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          if (mounted) {
            setState(() {
              _webImage = bytes;
              _pickedImage = File(pickedFile.path);
            });
          }
        } else {
          final File imageFile = File(pickedFile.path);
          if (await imageFile.exists()) {
            if (mounted) {
              setState(() {
                _pickedImage = imageFile;
              });
            }
          } else {
            throw Exception('Selected file does not exist');
          }
        }
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      
      String errorMessage = 'Failed to pick image';
      if (e.code == 'photo_access_denied') {
        errorMessage = 'Please grant photo access permission in app settings';
        if (!kIsWeb) {
          await openAppSettings();
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _pickedImage = null;
    _webImage = null;
    super.dispose();
  }
}