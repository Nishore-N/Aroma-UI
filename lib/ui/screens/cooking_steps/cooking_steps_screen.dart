import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/utils/item_image_resolver.dart';
import '../../../core/utils/extreme_spring_physics.dart';
import 'step_ingredients_bottomsheet.dart';
import 'step_timer_bottomsheet.dart';
import '../completion/completion_screen.dart';
import '../../../core/utils/recipe_formatter.dart';
import '../../../data/services/recipe_detail_service.dart';

class CookingStepsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> steps;
  final int currentStep;
   final List<Map<String, dynamic>> allIngredients;
  final String recipeName;
  final int servings;
  final Map<String, String> initialGeneratedImages; // Add this

  const CookingStepsScreen({
    super.key,
    required this.steps,
    required this.currentStep,
    required this.allIngredients,
    required this.recipeName,
    this.servings = 4,
    this.initialGeneratedImages = const {}, // Default to empty
  });

  @override
  State<CookingStepsScreen> createState() => _CookingStepsScreenState();
}

class _CookingStepsScreenState extends State<CookingStepsScreen> {
  Timer? _timer;
  int _totalSeconds = 0;
  int _secondsRemaining = 0;
  bool _isTimerRunning = false;
  bool _isTimerSet = false;
  late Map<String, String> _locallyGeneratedImages;
  final Set<String> _pendingGenerations = {};

  @override
  void initState() {
    super.initState();
    _locallyGeneratedImages = Map<String, String>.from(widget.initialGeneratedImages);
    _checkAndGenerateImages();
  }

  void _checkAndGenerateImages() {
    // Check allIngredients
    for (var item in widget.allIngredients) {
      _triggerGenerationIfMissing(item);
    }

    // Check current step ingredients
    final step = widget.steps[widget.currentStep - 1];
    if (step['ingredients_used'] != null && step['ingredients_used'] is List) {
      for (var item in (step['ingredients_used'] as List)) {
        if (item is Map<String, dynamic>) {
          _triggerGenerationIfMissing(item);
        }
      }
    }
  }

  void _triggerGenerationIfMissing(Map<String, dynamic> item) {
    final name = (item['item'] ?? item['name'] ?? '').toString();
    final imageUrl = item['image_url']?.toString() ?? 
                   item['imageUrl']?.toString() ?? 
                   item['image']?.toString() ?? '';

    if (name.isNotEmpty && imageUrl.isEmpty && !_locallyGeneratedImages.containsKey(name) && !_pendingGenerations.contains(name)) {
      _generateImageForIngredient(name);
    }
  }

  Future<void> _generateImageForIngredient(String name) async {
    if (_pendingGenerations.contains(name)) return;

    setState(() {
      _pendingGenerations.add(name);
    });

    try {
      final generatedUrl = await RecipeDetailService.generateImage(name, isRecipe: false);
      if (mounted) {
        if (generatedUrl != null) {
          setState(() {
            _locallyGeneratedImages[name] = generatedUrl;
          });
        }
        setState(() {
          _pendingGenerations.remove(name);
        });
      }
    } catch (e) {
      debugPrint('❌ [CookingStepsScreen] Error generating image for $name: $e');
      if (mounted) {
        setState(() {
          _pendingGenerations.remove(name);
        });
      }
    }
  }

  Widget _buildIngredientIcon(dynamic icon, String ingredientName, {double size = 48}) {
    if (icon is String && icon.isNotEmpty && (icon.startsWith('http://') || icon.startsWith('https://'))) {
      String imageUrl = icon;
      // Try to find better match if needed, but direct URL is fine
      if (imageUrl.startsWith('http://') && imageUrl.contains('s3')) {
          imageUrl = imageUrl.replaceFirst('http://', 'https://');
      }

      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size / 4),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size / 4),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(color: Colors.grey[100]),
            errorWidget: (context, url, error) => ItemImageResolver.getImageWidget(ingredientName, size: size),
          ),
        ),
      );
    }
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size / 4),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Center(
        child: ItemImageResolver.getImageWidget(ingredientName, size: size * 0.7),
      ),
    );
  }

  Widget _buildEmojiIcon(String ingredientName) {
    return Text(
      ItemImageResolver.getEmojiForIngredient(ingredientName),
      style: const TextStyle(fontSize: 30),
    );
  }

  Widget _buildDefaultIngredientIcon() {
    return ItemImageResolver.getImageWidget(
      'default_ingredient',
      size: 30,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (_isTimerRunning || !_isTimerSet) return;
    
    setState(() {
      _isTimerRunning = true;
      _secondsRemaining = 0;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining < _totalSeconds) {
        setState(() {
          _secondsRemaining++;
        });
      } else {
        _timer?.cancel();
        setState(() {
          _isTimerRunning = false;
        });
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isTimerRunning = false;
    });
  }

  void _setTimer(int minutes) {
    setState(() {
      _totalSeconds = minutes * 60;
      _secondsRemaining = 0;
      _isTimerSet = true;
      _isTimerRunning = false;
    });
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  void _showTimerBottomSheet() {
    showStepTimerBottomSheet(context).then((selectedMinutes) {
      if (selectedMinutes != null) {
        _setTimer(selectedMinutes);
        _startTimer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentSteps = widget.steps;
    
    if (currentSteps.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text(
            'No steps available',
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }
    
    if (widget.currentStep < 1 || widget.currentStep > currentSteps.length) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.recipeName),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Invalid step: ${widget.currentStep}',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 10),
              Text(
                'Available steps: ${currentSteps.length}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }
    
    final step = currentSteps[widget.currentStep - 1];
    final String instruction = (step['instruction'] ?? '').toString();
    
    List<Map<String, dynamic>> stepIngredients = [];
    
    if (step['ingredients_used'] != null) {
      final ingredientsData = step['ingredients_used'];
      if (ingredientsData is List) {
        stepIngredients = ingredientsData
            .whereType<Map<String, dynamic>>()
            .toList(growable: false);
      }
    }
    
    if (stepIngredients.isEmpty) {
      for (String fieldName in ['step_ingredients', 'ingredients', 'items']) {
        if (step[fieldName] != null) {
          final data = step[fieldName];
          if (data is List) {
            stepIngredients = data
                .whereType<Map<String, dynamic>>()
                .toList(growable: false);
            
            if (stepIngredients.isNotEmpty) {
              break;
            }
          }
        }
      }
    }
    
    if (stepIngredients.isEmpty && widget.allIngredients.isNotEmpty) {
      stepIngredients = widget.allIngredients;
    }
    
    final List<String> tips =
        (step['tips'] as List?)
        ?.where((e) => e != null)
        .map((e) => e.toString())
        .toList() 
    ?? [];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: ExtremeSpringPhysics(
            springStrength: 1000.0, 
            damping: 12.0, 
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Cooking Steps",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Text(
                    "Step ${widget.currentStep}",
                    style: const TextStyle(
                      fontSize: 18,
                      color: Color(0xFFFF6A45),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    " / ${currentSteps.length}",
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  children: [
                    Container(height: 6, color: Colors.grey.shade200),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 6,
                      width: (MediaQuery.of(context).size.width - 36) *
                          (widget.currentStep / currentSteps.length),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6A45),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              Divider(color: Colors.grey.shade200, thickness: 1.5),
              const SizedBox(height: 20),

              const Text(
                "Instruction",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 16),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFFFB99A), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFE734C).withOpacity(0.05),
                      offset: const Offset(0, 3),
                      blurRadius: 7,
                    ),
                    BoxShadow(
                      color: const Color(0xFFFE734C).withOpacity(0.04),
                      offset: const Offset(0, 12),
                      blurRadius: 12,
                    ),
                    BoxShadow(
                      color: const Color(0xFFFE734C).withOpacity(0.03),
                      offset: const Offset(0, 28),
                      blurRadius: 17,
                    ),
                    BoxShadow(
                      color: const Color(0xFFFE734C).withOpacity(0.01),
                      offset: const Offset(0, 50),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHighlightedText(instruction, stepIngredients),

                    const SizedBox(height: 22),

                    GestureDetector(
                      onTap: _isTimerRunning ? _stopTimer : (_isTimerSet ? _startTimer : _showTimerBottomSheet),
                      child: !_isTimerSet 
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF1EC),
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(
                                  color: const Color(0xFFFFC1A6),
                                  width: 2,
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.schedule_rounded, // Clock icon
                                    color: Color(0xFFFF6A45), // Orange color from image
                                    size: 24,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Add Timer',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF555555), // Dark grey text
                                    ),
                                  ),
                                ],
                              ),
                            )
                        : Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: _isTimerRunning 
                                ? Colors.white 
                                : (_isTimerSet && _secondsRemaining >= _totalSeconds && _totalSeconds > 0)
                                    ? const Color(0xFFE8F5E9)
                                    : const Color(0xFFFFF1EC),
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(
                              color: _isTimerRunning 
                                  ? const Color(0xFFFF6A45)
                                  : (_isTimerSet && _secondsRemaining >= _totalSeconds && _totalSeconds > 0)
                                      ? const Color(0xFF81C784)
                                      : const Color(0xFFFFC1A6),
                              width: _isTimerRunning ? 2.5 : 2,
                            ),
                            boxShadow: _isTimerRunning && _secondsRemaining <= 10
                                ? [
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.3),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    )
                                  ]
                                : (_isTimerSet && _secondsRemaining >= _totalSeconds && _totalSeconds > 0)
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF4CAF50).withOpacity(0.3),
                                          blurRadius: 20,
                                          spreadRadius: 2,
                                        )
                                      ]
                                    : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isTimerRunning 
                                    ? Icons.timer_outlined
                                    : (_isTimerSet && _secondsRemaining >= _totalSeconds && _totalSeconds > 0)
                                        ? Icons.check_circle_outline
                                        : Icons.timer_outlined,
                                color: _isTimerRunning 
                                    ? const Color(0xFFFF6A45) 
                                    : (_isTimerSet && _secondsRemaining >= _totalSeconds && _totalSeconds > 0)
                                        ? const Color(0xFF4CAF50)
                                        : const Color(0xFF555555),
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isTimerRunning 
                                    ? _formatTime(_secondsRemaining)
                                    : _isTimerSet 
                                        ? (_secondsRemaining >= _totalSeconds && _totalSeconds > 0)
                                            ? 'Completed'
                                            : '00:00'
                                        : 'Add Timer',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _isTimerRunning 
                                      ? const Color(0xFFFF6A45)
                                      : (_isTimerSet && _secondsRemaining >= _totalSeconds && _totalSeconds > 0)
                                          ? const Color(0xFF4CAF50)
                                          : const Color(0xFF555555),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Ingredients",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => StepIngredientsBottomSheet(
                          stepIngredients: stepIngredients,
                          allIngredients: widget.allIngredients,
                          currentStepIndex: widget.currentStep - 1,
                          servings: widget.servings,
                          locallyGeneratedImages: _locallyGeneratedImages,
                        ),
                      );
                    },
                    child: const Text(
                      "View all",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF6A45),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              const Text(
                "This Step's Ingredients",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 22),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: stepIngredients.map<Widget>((ingredient) {
                    final name = (ingredient['item'] ?? ingredient['name'] ?? 'Ingredient').toString();
                    final baseQty = ingredient['quantity'] ?? ingredient['qty'] ?? '';
                    final unit = ingredient['unit']?.toString() ?? '';
                    final qty = RecipeFormatter.formatQuantity(baseQty, widget.servings, unit);
                    
                    var imageUrl = ingredient['image_url']?.toString() ?? 
                                 ingredient['imageUrl']?.toString() ?? 
                                 ingredient['image']?.toString() ?? '';
                    
                    if (imageUrl.isEmpty && widget.allIngredients.isNotEmpty) {
                      for (final allIng in widget.allIngredients) {
                        final allName = (allIng['item'] ?? allIng['name'] ?? '').toString().toLowerCase().trim();
                        final currentName = name.toLowerCase().trim();
                        if (allName == currentName || currentName.contains(allName) || allName.contains(currentName)) {
                          imageUrl = allIng['image_url']?.toString() ?? 
                                     allIng['imageUrl']?.toString() ?? 
                                     allIng['image']?.toString() ?? '';
                          break;
                        }
                      }
                    }
                    
                     if (imageUrl.isEmpty) {
                      imageUrl = _locallyGeneratedImages[name] ?? '';
                    }
                    
                    final icon = imageUrl.isNotEmpty ? imageUrl : name; 

                    return Container(
                      margin: const EdgeInsets.only(right: 12, bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFFCABB),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildIngredientIcon(icon, name, size: 36),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF212529),
                                ),
                              ),
                              if (qty.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  qty,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6C757D),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 26),

              if (tips.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Tips & Doubts",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...tips.map((tip) {
                        final parts = tip.split('?');
                        final question = parts.isNotEmpty ? '${parts[0].trim()}?' : '';
                        final answer = parts.length > 1 ? parts.sublist(1).join('?').trim() : '';
                        
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                question,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.2,
                                  color: Colors.black.withOpacity(0.8),
                                ),
                              ),
                              if (answer.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  answer,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    height: 1.2,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],

              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 58,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: const Color(0xFFFF6A45),
                          width: 2,
                        ),
                      ),
                      child: TextButton(
                        onPressed: () {
                          if (widget.currentStep > 1) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CookingStepsScreen(
                                  steps: widget.steps,
                                  currentStep: widget.currentStep - 1,
                                  allIngredients: widget.allIngredients,
                                  recipeName: widget.recipeName,
                                  servings: widget.servings,
                                  initialGeneratedImages: _locallyGeneratedImages,
                                ),
                              ),
                            );
                          } else {
                            Navigator.pop(context);
                          }
                        },
                        child: const Text(
                          "Back",
                          style: TextStyle(
                            color: Color(0xFFFF6A45),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Container(
                      height: 58,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6A45),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: TextButton(
                        onPressed: () {
                          if (widget.currentStep < widget.steps.length) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CookingStepsScreen(
                                  steps: widget.steps,
                                  currentStep: widget.currentStep + 1,
                                  allIngredients: widget.allIngredients,
                                  recipeName: widget.recipeName,
                                  servings: widget.servings,
                                  initialGeneratedImages: _locallyGeneratedImages, // Pass accumulated images
                                ),
                              ),
                            );
                          } else {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CompletionScreen(recipeName: widget.recipeName),
                              ),
                            );
                          }
                        },
                        child: Text(
                          widget.currentStep < widget.steps.length ? "Next" : "Done",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightedText(String text, List<Map<String, dynamic>> stepIngredients) {
    if (text.isEmpty) return const SizedBox.shrink();

    final List<String> highlightTerms = [];
    for (final ing in stepIngredients) {
      final name = (ing['item'] ?? ing['name'] ?? '').toString().toLowerCase();
      if (name.isNotEmpty) {
        highlightTerms.add(name);
        final words = name.split(' ');
        for (final word in words) {
          if (word.length > 3 && !['with', 'from', 'into', 'your'].contains(word)) {
            highlightTerms.add(word);
          }
        }
      }
    }

    highlightTerms.sort((a, b) => b.length.compareTo(a.length));
    final timeRegex = RegExp(r'(\d+[-–\d+]*)?\s*(minutes|mins|hours|hrs|seconds|secs)', caseSensitive: false);
    
    final List<TextSpan> spans = [];
    int currentPos = 0;

    final escapedTerms = highlightTerms.where((t) => t.isNotEmpty).map((t) => RegExp.escape(t)).toList();
    String pattern = escapedTerms.isNotEmpty 
        ? '(${escapedTerms.join('|')}|${timeRegex.pattern})'
        : timeRegex.pattern;
    
    final combinedRegex = RegExp(pattern, caseSensitive: false);
    final matches = combinedRegex.allMatches(text);
    
    for (final match in matches) {
      if (match.start > currentPos) {
        spans.add(TextSpan(
          text: text.substring(currentPos, match.start),
          style: const TextStyle(fontSize: 16, height: 1.6, color: Color(0xFF2D2D2D)),
        ));
      }
      
      spans.add(TextSpan(
        text: text.substring(match.start, match.end),
        style: const TextStyle(
          fontSize: 16,
          height: 1.6,
          fontWeight: FontWeight.w900,
          color: Color(0xFFC04423),
        ),
      ));
      currentPos = match.end;
    }
    
    if (currentPos < text.length) {
      spans.add(TextSpan(
        text: text.substring(currentPos),
        style: const TextStyle(fontSize: 16, height: 1.6, color: Color(0xFF2D2D2D)),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }
}