import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A premium, animated loader for a cooking state.
/// Features rising steam, a bouncing utensil icon, and pulsing text.
class CookingLoader extends StatefulWidget {
  final String message;
  final Color primaryColor;
  final Color secondaryColor;

  const CookingLoader({
    super.key,
    this.message = "your weekly recipes are cooking",
    this.primaryColor = const Color(0xFFFF6B6B), // Vibrant coral
    this.secondaryColor = const Color(0xFFFFD93D), // Warm yellow
  });

  @override
  State<CookingLoader> createState() => _CookingLoaderState();
}

class _CookingLoaderState extends State<CookingLoader>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _steamController;
  late AnimationController _bounceController;

  @override
  void initState() {
    super.initState();

    // Text pulsing animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Steam rising animation
    _steamController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // Pan bouncing animation
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _steamController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // Steam Bubbles
                SizedBox(
                  height: 120,
                  width: 100,
                  child: AnimatedBuilder(
                    animation: _steamController,
                    builder: (context, child) {
                      return Stack(
                        children: List.generate(3, (index) {
                          double progress = (_steamController.value + (index / 3)) % 1.0;
                          return Positioned(
                            bottom: 20 + (progress * 80),
                            left: 30 + (math.sin(progress * math.pi * 2 + index) * 20),
                            child: Opacity(
                              opacity: (1 - progress).clamp(0, 1),
                              child: Container(
                                height: 10 + (index * 4),
                                width: 10 + (index * 4),
                                decoration: BoxDecoration(
                                  color: widget.primaryColor.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ),

                // Bouncing Pan/Pot Icon
                ScaleTransition(
                  scale: Tween<double>(begin: 0.95, end: 1.05).animate(
                    CurvedAnimation(
                      parent: _bounceController,
                      curve: Curves.easeInOut,
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: widget.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.restaurant_menu,
                      size: 60,
                      color: widget.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Pulsing Text
            FadeTransition(
              opacity: Tween<double>(begin: 0.4, end: 1.0).animate(
                CurvedAnimation(
                  parent: _pulseController,
                  curve: Curves.easeInOut,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  widget.message.toLowerCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                    color: Colors.black.withOpacity(0.8),
                    fontFamily: 'Inter', // Fallback to system if not loaded
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Animated Progress Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return AnimatedBuilder(
                  animation: _steamController,
                  builder: (context, child) {
                    double progress = (_steamController.value + (index / 3)) % 1.0;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 6,
                      width: 6,
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
    );
  }
}