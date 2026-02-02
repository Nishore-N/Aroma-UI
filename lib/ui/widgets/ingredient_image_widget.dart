import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/services/pantry_image_service.dart';

class IngredientThumbnail extends StatefulWidget {
  final String ingredientName;
  final double size;
  final String? imageUrl;
  final String? assetFallbackPath;
  final bool enableGeneration;

  const IngredientThumbnail({
    super.key,
    required this.ingredientName,
    this.size = 56,
    this.imageUrl,
    this.assetFallbackPath,
    this.enableGeneration = false,
  });

  @override
  State<IngredientThumbnail> createState() => _IngredientThumbnailState();
}

class _IngredientThumbnailState extends State<IngredientThumbnail> {
  String? _generatedImageUrl;
  bool _isGenerating = false;
  bool _generationAttempted = false;

  @override
  Widget build(BuildContext context) {
    // If we have a generated image, use it effectively as the imageUrl
    final effectiveImageUrl = widget.imageUrl ?? _generatedImageUrl;

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(widget.size * 0.2),
      ),
      child: effectiveImageUrl != null && effectiveImageUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(widget.size * 0.2),
              child: Builder(builder: (context) {
                String finalUrl = effectiveImageUrl;
                if (finalUrl.startsWith('http://') && finalUrl.contains('s3')) {
                  finalUrl = finalUrl.replaceFirst('http://', 'https://');
                }

                return CachedNetworkImage(
                  imageUrl: finalUrl,
                  width: widget.size,
                  height: widget.size,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      Container(color: Colors.grey[200]),
                  errorWidget: (context, url, error) => _buildFallback(),
                );
              }),
            )
          : _buildFallback(),
    );
  }

  Widget _buildFallback() {
    // If assets are available, try to show them
    if (widget.assetFallbackPath != null &&
        widget.assetFallbackPath!.isNotEmpty &&
        // Hack: Check if it is NOT the generic fallback if we want to support partial assets
        !widget.assetFallbackPath!.contains('temp_pantry.png')) {
      return Image.asset(
        widget.assetFallbackPath!,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
           // If asset load fails, trigger generation if enabled
           if (widget.enableGeneration) {
             _triggerGenerationIfNeeded();
           }
           return _isGenerating ? _buildLoading() : _buildIconFallback();
        },
      );
    }

    // If we are here, it means no specific asset was found or provided
    if (widget.enableGeneration) {
      _triggerGenerationIfNeeded();
      
      if (_isGenerating) {
        return _buildLoading();
      }
    }

    return _buildIconFallback();
  }
  
  void _triggerGenerationIfNeeded() {
    if (_generationAttempted || _isGenerating || widget.ingredientName.isEmpty) {
      return;
    }
    
    // Defer to next frame to avoid build-phase side effects
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _generateImage();
      }
    });
  }

  Future<void> _generateImage() async {
    if (_generationAttempted) return;
    
    setState(() {
      _isGenerating = true;
      _generationAttempted = true;
    });

    try {
      // Import locally to avoid circular dependencies if any, though top-level import is better
      // Assuming PantryImageService is available in the project
      final url = await PantryImageService().generateItemImage(widget.ingredientName);
      
      if (mounted && url != null) {
        setState(() {
          _generatedImageUrl = url;
          _isGenerating = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _isGenerating = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error generating image thumbnail: $e');
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }
  
  Widget _buildLoading() {
    return Center(
      child: SizedBox(
        width: widget.size * 0.4,
        height: widget.size * 0.4,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.orange.shade300,
        ),
      ),
    );
  }

  Widget _buildIconFallback() {
    return Center(
      child: Icon(
        Icons.restaurant_menu,
        size: widget.size * 0.6,
        color: Colors.grey.shade400,
      ),
    );
  }
}

class IngredientImageThumbnail extends IngredientThumbnail {
  const IngredientImageThumbnail({
    super.key,
    required super.ingredientName,
    super.size,
    super.imageUrl,
    super.assetFallbackPath,
    super.enableGeneration,
  });
}
