import 'package:flutter/material.dart';

class ShimmerEffect extends StatefulWidget {
  final double width;
  final double height;
  final double radius;
  final Color? baseColor;
  final Color? highlightColor;
  final BoxShape shape;

  const ShimmerEffect({
    Key? key,
    required this.width,
    required this.height,
    this.radius = 4.0,
    this.baseColor,
    this.highlightColor,
    this.shape = BoxShape.rectangle,
  }) : super(key: key);

  @override
  _ShimmerEffectState createState() => _ShimmerEffectState();

  // Convenience constructors
  factory ShimmerEffect.rectangular({
    required double width,
    required double height,
    double radius = 4.0,
  }) {
    return ShimmerEffect(
      width: width,
      height: height,
      radius: radius,
      shape: BoxShape.rectangle,
    );
  }

  factory ShimmerEffect.circular({
    required double size,
    Color? baseColor,
    Color? highlightColor,
  }) {
    return ShimmerEffect(
      width: size,
      height: size,
      shape: BoxShape.circle,
      baseColor: baseColor,
      highlightColor: highlightColor,
    );
  }
}

class _ShimmerEffectState extends State<ShimmerEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    final theme = Theme.of(context);
    final baseColor = widget.baseColor ?? theme.highlightColor.withOpacity(0.2);
    final highlightColor = widget.highlightColor ?? theme.highlightColor.withOpacity(0.5);

    _colorAnimation = ColorTween(
      begin: baseColor,
      end: highlightColor,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (_, __) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: _colorAnimation.value,
            shape: widget.shape,
            borderRadius: widget.shape == BoxShape.rectangle
                ? BorderRadius.circular(widget.radius)
                : null,
          ),
        );
      },
    );
  }
}

class ShimmerList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final double spacing;
  final EdgeInsets padding;

  const ShimmerList({
    Key? key,
    this.itemCount = 5,
    this.itemHeight = 80.0,
    this.spacing = 8.0,
    this.padding = EdgeInsets.zero,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding,
      itemCount: itemCount,
      itemBuilder: (_, index) => Padding(
        padding: EdgeInsets.only(bottom: spacing),
        child: ShimmerEffect.rectangular(
          width: double.infinity,
          height: itemHeight,
          radius: 8.0,
        ),
      ),
    );
  }
}
