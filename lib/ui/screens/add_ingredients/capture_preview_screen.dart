import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:typed_data';

import '../../../core/theme/app_colors.dart';
import 'review_ingredients_screen.dart';
import '../../../core/enums/scan_mode.dart';
import '../../../data/services/pantry_add_service.dart';
import '../pantry/pantry_review_ingredients_screen.dart';
import '../pantry/review_items_screen.dart';
import '../pantry/pantry_search_add_screen.dart';

class CapturePreviewScreen extends StatefulWidget {
  final ScanMode mode;

  const CapturePreviewScreen({
    super.key,
    required this.mode,
  });

  @override
  State<CapturePreviewScreen> createState() => _CapturePreviewScreenState();
}

class _CapturePreviewScreenState extends State<CapturePreviewScreen> {
  CameraController? _controller;
  Future<void>? _initFuture;
  final ImagePicker _picker = ImagePicker();
  bool _isCapturing = false;

  Future<XFile?> _captureImage() async {
    try {
      if (_controller == null) {
        debugPrint("Camera controller not initialized");
        return null;
      }
      
      final XFile? image = await _controller!.takePicture();
      debugPrint("Image captured successfully: ${image?.path}");
      return image;
    } catch (e) {
      debugPrint("Error capturing image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture photo: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  Future<void> _initCamera() async {
    try {
      // Request camera permission first
      final cameraPermission = await Permission.camera.request();
      
      if (cameraPermission.isDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Camera permission is required to scan receipts'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      if (cameraPermission.isPermanentlyDenied) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Camera Permission Required'),
              content: const Text('Please enable camera permission in app settings to use the scanning feature.'),
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

      final List<CameraDescription> cams = await availableCameras();
      if (cams.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No cameras available on this device'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Try to use back camera first, then front camera
      CameraDescription? selectedCamera;
      for (CameraDescription cam in cams) {
        if (cam.lensDirection == CameraLensDirection.back) {
          selectedCamera = cam;
          break;
        }
      }
      // Fallback to first camera if back camera not found
      selectedCamera ??= cams.first;
      
      final CameraController controller = CameraController(
        selectedCamera,
        ResolutionPreset.medium, // Faster than high
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      
      _controller = controller;
      
      await controller.initialize();
      if (!mounted) return;
      
      setState(() {});
    } catch (e) {
      debugPrint("Camera initialization error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize camera: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToManualEntry() {
    if (widget.mode == ScanMode.pantry) {
      // Navigate to pantry search add screen for manual entry
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const PantrySearchAddScreen(),
        ),
      );
    } else {
      // Navigate to cooking ingredient entry
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const ReviewIngredientsScreen(
            capturedImage: null,
            scanResult: null,
          ),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    print("🔥 SCANNER MODE = ${widget.mode}");
    _initFuture = _initCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: FutureBuilder<void>(
          future: _initFuture,
          builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
            return Stack(
              children: [
                /// Camera Preview or fallback
                Positioned.fill(
                  child: (_controller != null && _controller!.value.isInitialized)
                      ? CameraPreview(_controller!)
                      : Container(color: Colors.black),
                ),

                /// Fade to dark at bottom (overlay gradient)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.center,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.85),
                        ],
                      ),
                    ),
                  ),
                ),

                /// Scanning frame (rounded corners) - smaller so it doesn't touch bottom
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(26, 90, 26, 180),
                    child: CustomPaint(painter: _ScannerFrame()),
                  ),
                ),

                /// Back Button
                Positioned(
                  top: 16,
                  left: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.black),
                    ),
                  ),
                ),

                /// --- BOTTOM SHUTTER + TEXT ---
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 40, left: 32, right: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        /// Controls Row (center shutter only)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const SizedBox(width: 56),

                            /// Capture button
                            GestureDetector(
                              onTap: _isCapturing ? null : () async {
  try {
    setState(() => _isCapturing = true);
    
    // Capture image first
    final XFile? image = await _captureImage();
    if (image == null || !mounted) {
      setState(() => _isCapturing = false);
      return;
    }

    // Navigate instantly - no delays
    if (widget.mode == ScanMode.cooking) {
      // 🍳 COOKING FLOW - Use normal review ingredients screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ReviewIngredientsScreen(
            capturedImage: image,
            scanResult: null,
          ),
        ),
      );
    } else {
      // 🧺 PANTRY FLOW - Use pantry review ingredients screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PantryReviewIngredientsScreen(
            capturedImage: image,
            mode: ScanMode.pantry,
          ),
        ),
      );
    }
                                } catch (e) {
                                  setState(() => _isCapturing = false);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to capture or scan: ${e.toString()}'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                              child: Container(
                                height: 84,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 5),
                                ),
                                child: Center(
                                  child: _isCapturing
                                      ? Container(
                                          width: 84,
                                          height: 84,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 5),
                                          ),
                                          child: Center(
                                            child: Container(
                                              width: 62,
                                              height: 62,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.white,
                                              ),
                                              child: const Center(
                                                child: SizedBox(
                                                  width: 30,
                                                  height: 30,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 3,
                                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          )
                                        )
                                      : Container(
                                          width: 84,
                                          height: 84,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 5),
                                          ),
                                          child: Center(
                                            child: Container(
                                              width: 62,
                                              height: 62,
                                              decoration: const BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 56),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Scanner Frame Painter
class _ScannerFrame extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final double cornerSize = 24.0;
    final double cornerWidth = 3.0;
    final double cornerLength = cornerSize;

    // Draw left-top corner (L shape)
    canvas.drawLine(
      Offset(0, cornerLength),
      Offset.zero,
      paint..strokeWidth = cornerWidth,
    );
    canvas.drawLine(
      Offset.zero,
      Offset(cornerLength, 0),
      paint..strokeWidth = cornerWidth,
    );

    // Draw right-top corner (mirrored L shape)
    canvas.drawLine(
      Offset(size.width - cornerLength, 0),
      Offset(size.width, 0),
      paint..strokeWidth = cornerWidth,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width, cornerLength),
      paint..strokeWidth = cornerWidth,
    );

    // Draw left-bottom corner (upside-down L shape)
    canvas.drawLine(
      Offset(0, size.height - cornerLength),
      Offset(0, size.height),
      paint..strokeWidth = cornerWidth,
    );
    canvas.drawLine(
      Offset(0, size.height),
      Offset(cornerLength, size.height),
      paint..strokeWidth = cornerWidth,
    );

    // Draw right-bottom corner (upside-down mirrored L shape)
    canvas.drawLine(
      Offset(size.width - cornerLength, size.height),
      Offset(size.width, size.height),
      paint..strokeWidth = cornerWidth,
    );
    canvas.drawLine(
      Offset(size.width, size.height - cornerLength),
      Offset(size.width, size.height),
      paint..strokeWidth = cornerWidth,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
