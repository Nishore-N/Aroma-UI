import 'package:flutter/material.dart';
import 'dart:math' as math;

class RecipeGenerationAnimation extends StatefulWidget {
  final String message;
  final Color primaryColor;
  final Color secondaryColor;
  final bool isActive;

  const RecipeGenerationAnimation({
    super.key,
    this.message = "generating your recipes",
    this.primaryColor = const Color(0xFFFF6A45), // Orange accent from app
    this.secondaryColor = const Color(0xFFFFD93D), // Warm yellow
    this.isActive = true,
  });

  @override
  State<RecipeGenerationAnimation> createState() => _RecipeGenerationAnimationState();
}

class _RecipeGenerationAnimationState extends State<RecipeGenerationAnimation>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _sparkleController;
  late AnimationController _textController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    
    // Main animation controller (2 second loop)
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    
    // Sparkle animation controller (faster, 1.5 seconds)
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    // Text animation controller (1 second for dots)
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    if (widget.isActive) {
      _mainController.repeat();
      _sparkleController.repeat();
      _textController.repeat();
    }

    // Main pot/utensil scaling animation
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: Curves.easeInOut,
      ),
    );

    // Expanding waves opacity
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: Curves.easeOut,
      ),
    );

    // Subtle rotation for sparkles
    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _sparkleController,
        curve: Curves.linear,
      ),
    );
  }

  @override
  void didUpdateWidget(RecipeGenerationAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _mainController.repeat();
        _sparkleController.repeat();
        _textController.repeat();
      } else {
        _mainController.stop();
        _sparkleController.stop();
        _textController.stop();
      }
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _sparkleController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final centerX = screenSize.width / 2;
    final centerY = screenSize.height / 2;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // Center the entire animation stack
            Positioned(
              left: centerX - 150, // Center the 300px animation area
              top: centerY - 200, // Center vertically with space for text
              child: Column(
                children: [
                  // Main cooking animation
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer expanding wave
                      AnimatedBuilder(
                        animation: _mainController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: Tween<double>(begin: 1.0, end: 1.8).evaluate(_mainController),
                            child: Opacity(
                              opacity: _opacityAnimation.value,
                              child: Container(
                                width: 300,
                                height: 300,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: widget.primaryColor.withOpacity(0.3),
                                    width: 3.0,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      
                      // Middle expanding wave
                      AnimatedBuilder(
                        animation: _mainController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: Tween<double>(begin: 0.7, end: 1.4).evaluate(_mainController),
                            child: Opacity(
                              opacity: Tween<double>(begin: 0.5, end: 0.0).evaluate(_mainController),
                              child: Container(
                                width: 220,
                                height: 220,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: widget.secondaryColor.withOpacity(0.4),
                                    width: 2.5,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      
                      // Central cooking pot with pulse
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: widget.primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.restaurant_menu,
                            size: 50,
                            color: widget.primaryColor,
                          ),
                        ),
                      ),
                      
                      // Rotating food items continuously around center
                      ...List.generate(5, (index) {
                        return AnimatedBuilder(
                          animation: _sparkleController,
                          builder: (context, child) {
                            final angle = (index * 72.0) * (math.pi / 180.0); // 360/5 = 72 degrees - equal spacing
                            
                            // Continuous rotation around center - no breathing reset
                            final radius = 110.0; // Fixed radius for continuous circular motion
                            
                            // Slower continuous rotation using sparkle controller
                            final rotationAngle = angle + (_sparkleController.value * 0.8 * math.pi); // Reduced speed
                            final itemX = math.cos(rotationAngle) * radius;
                            final itemY = math.sin(rotationAngle) * radius;
                            
                            // Food item emojis and colors
                            final foodItems = [
                              {'emoji': '🍎', 'name': 'Apple', 'color': Colors.red},
                              {'emoji': '🍔', 'name': 'Burger', 'color': Colors.orange},
                              {'emoji': '🍕', 'name': 'Pizza', 'color': Colors.red.shade700},
                              {'emoji': '🥭', 'name': 'Mango', 'color': Colors.orange.shade700},
                              {'emoji': '🍟', 'name': 'French Fries', 'color': Colors.yellow.shade700},
                            ];
                            
                            final foodItem = foodItems[index];
                            final emoji = foodItem['emoji'] as String;
                            final color = foodItem['color'] as Color;
                            
                            // Consistent size for all items
                            final itemSize = 45.0;
                            
                            return Positioned(
                              left: 150 + itemX - (itemSize / 2),
                              top: 150 + itemY - (itemSize / 2),
                              child: Transform.rotate(
                                angle: -rotationAngle, // Counter-rotate to keep items upright
                                child: Container(
                                  width: itemSize,
                                  height: itemSize,
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: color.withOpacity(0.9),
                                      width: 2.0,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: color.withOpacity(0.4),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      emoji,
                                      style: const TextStyle(fontSize: 22),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      }),
                    ],
                  ),
                  
                  const SizedBox(height: 80),
                  
                  // Animated text with dots
                  _AnimatedCookingText(
                    text: widget.message,
                    textStyle: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Progress indicator dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      return AnimatedBuilder(
                        animation: _mainController,
                        builder: (context, child) {
                          double progress = (_mainController.value + (index / 3)) % 1.0;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            height: 12,
                            width: 12,
                            decoration: BoxDecoration(
                              color: widget.primaryColor.withOpacity(1 - progress),
                              shape: BoxShape.circle,
                            ),
                          );
                        },
                      );
                    }),
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

class _AnimatedCookingText extends StatefulWidget {
  final String text;
  final TextStyle textStyle;

  const _AnimatedCookingText({
    required this.text,
    required this.textStyle,
  });

  @override
  State<_AnimatedCookingText> createState() => _AnimatedCookingTextState();
}

class _AnimatedCookingTextState extends State<_AnimatedCookingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _dotCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _controller.reverse();
        } else if (status == AnimationStatus.dismissed) {
          setState(() {
            _dotCount = (_dotCount + 1) % 4;
          });
          _controller.forward();
        }
      });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dots = '.' * _dotCount;
    return Text(
      '${widget.text}$dots',
      style: widget.textStyle,
      textAlign: TextAlign.center,
    );
  }
}