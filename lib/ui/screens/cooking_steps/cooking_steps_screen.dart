import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/utils/item_image_resolver.dart';
import '../../../core/utils/extreme_spring_physics.dart';
import 'step_ingredients_bottomsheet.dart';
import 'step_timer_bottomsheet.dart';
import '../completion/completion_screen.dart';

class CookingStepsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> steps;
  final int currentStep;
  final List<Map<String, dynamic>> allIngredients;
  final String recipeName;

  const CookingStepsScreen({
    super.key,
    required this.steps,
    required this.currentStep,
    required this.allIngredients,
    required this.recipeName,
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

  @override
  void initState() {
    super.initState();
  }

  Widget _buildIngredientIcon(dynamic icon, String ingredientName) {
    if (icon is String && icon.isNotEmpty && (icon.startsWith('http://') || icon.startsWith('https://'))) {
      String imageUrl = icon;
      // Try to find better match if needed, but direct URL is fine
      if (imageUrl.startsWith('http://') && imageUrl.contains('s3')) {
          imageUrl = imageUrl.replaceFirst('http://', 'https://');
      }

      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(color: Colors.grey[200]),
            errorWidget: (context, url, error) => ItemImageResolver.getImageWidget(ingredientName, size: 48),
          ),
        ),
      );
    }
    
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: ItemImageResolver.getImageWidget(ingredientName, size: 30),
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
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Text(
                    "Step ${widget.currentStep}",
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFFFF6A45),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    " / ${currentSteps.length}",
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Stack(
                children: [
                  Container(height: 4, color: Colors.grey.shade300),
                  Container(
                    height: 4,
                    width: MediaQuery.of(context).size.width *
                        (widget.currentStep / currentSteps.length),
                    color: const Color(0xFFFF6A45),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Divider(color: Colors.grey.shade300, thickness: 1.2),
              const SizedBox(height: 18),

              const Text(
                "Instruction",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 16),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Color(0xFFFFB99A), width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      instruction,
                      style: const TextStyle(
                        fontSize: 17,
                        height: 1.55,
                      ),
                    ),

                    const SizedBox(height: 22),

                    GestureDetector(
                      onTap: _isTimerRunning ? _stopTimer : (_isTimerSet ? _startTimer : _showTimerBottomSheet),
                      child: Container(
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

              const SizedBox(height: 8),

              const Text(
                "This Step's Ingredients",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 14),

              Column(
                children: stepIngredients.map<Widget>((ingredient) {
                  final name = (ingredient['item'] ?? ingredient['name'] ?? 'Ingredient').toString();
                  final qty = (ingredient['quantity']?.toString() ?? ingredient['qty']?.toString() ?? '');
                  
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
                  
                  final icon = imageUrl.isNotEmpty ? imageUrl : name; 

                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFFFDCCD),
                        width: 1.6,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        _buildIngredientIcon(icon, name),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                              if (qty.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  qty,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF7A7A7A),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
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
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.2,
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
                        onPressed: () => Navigator.pop(context),
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
                                ),
                              ),
                            );
                          } else {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CompletionScreen(),
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
}