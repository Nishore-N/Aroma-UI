import 'package:flutter/material.dart';
import 'dart:math' as math;

class ScanningAnimation extends StatefulWidget {
  final double size;
  final Color primaryColor;
  final String? scanningText;
  final bool isActive;

  const ScanningAnimation({
    super.key,
    this.size = 200.0,
    this.primaryColor = Colors.blue,
    this.scanningText,
    this.isActive = true,
  });

  @override
  State<ScanningAnimation> createState() => _ScanningAnimationState();
}

class _ScanningAnimationState extends State<ScanningAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    
    if (widget.isActive) {
      _controller.repeat();
    }

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.8).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void didUpdateWidget(ScanningAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Animated radar waves
        Stack(
          alignment: Alignment.center,
          children: [
            // Outer ring
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Opacity(
                    opacity: _opacityAnimation.value,
                    child: Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.primaryColor.withOpacity(0.5),
                          width: 2.0,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            // Middle ring
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: Tween<double>(
                    begin: 0.6,
                    end: 1.2,
                  ).animate(CurvedAnimation(
                    parent: _controller,
                    curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
                  )).value,
                  child: Opacity(
                    opacity: Tween<double>(
                      begin: 0.3,
                      end: 0.0,
                    ).animate(CurvedAnimation(
                      parent: _controller,
                      curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
                    )).value,
                    child: Container(
                      width: widget.size * 0.7,
                      height: widget.size * 0.7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.primaryColor.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            // Search icon with pulse
            GestureDetector(
              onTap: () {
                // Haptic feedback
                // HapticFeedback.lightImpact();
                // Scale animation on tap
                _controller
                  ..reset()
                  ..forward();
              },
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 500),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 1.0 + (0.1 * value),
                    child: child,
                  );
                },
                child: Container(
                  width: widget.size * 0.3,
                  height: widget.size * 0.3,
                  decoration: BoxDecoration(
                    color: widget.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.search,
                    size: widget.size * 0.2,
                    color: widget.primaryColor,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Scanning text with animated dots
        if (widget.scanningText != null) ...[
          const SizedBox(height: 24),
          _AnimatedScanningText(
            text: widget.scanningText!,
            textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ],
    );
  }
}

class _AnimatedScanningText extends StatefulWidget {
  final String text;
  final TextStyle? textStyle;

  const _AnimatedScanningText({
    required this.text,
    this.textStyle,
  });

  @override
  State<_AnimatedScanningText> createState() => _AnimatedScanningTextState();
}

class _AnimatedScanningTextState extends State<_AnimatedScanningText>
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
    );
  }
}
