import 'package:flutter/material.dart';

class CustomSearchIcon extends StatelessWidget {
  const CustomSearchIcon({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _CustomSearchIconPainter(),
    );
  }
}

class _CustomSearchIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 40;
    
    // Scale the SVG to fit the container
    canvas.translate(0, 0);
    canvas.scale(scale, scale);

    // Background rectangle with rounded corners
    final backgroundPaint = Paint()
      ..color = const Color(0xFFF0EEEE)
      ..style = PaintingStyle.fill;

    final backgroundPath = Path();
    backgroundPath.addRRect(RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, 40, 40),
      const Radius.circular(16),
    ));
    canvas.drawPath(backgroundPath, backgroundPaint);

    // Search icon (magnifying glass)
    final iconPaint = Paint()
      ..color = const Color(0xFF333333)
      ..style = PaintingStyle.fill;

    final iconPath = Path();
    
    // Magnifying glass handle
    iconPath.moveTo(27.75, 26.75);
    iconPath.cubicTo(28.0625, 27.0312, 28.0625, 27.5, 27.75, 27.7812);
    iconPath.cubicTo(27.625, 27.9375, 27.4375, 28, 27.25, 28);
    iconPath.cubicTo(27.0312, 28, 26.8438, 27.9375, 26.7188, 27.7812);
    iconPath.lineTo(22.5312, 23.5938);
    
    // Magnifying glass circle
    iconPath.cubicTo(21.4062, 24.5, 20, 25, 18.5, 25);
    iconPath.cubicTo(14.9062, 25, 12, 22.0938, 12, 18.5);
    iconPath.cubicTo(12, 14.9375, 14.9062, 12, 18.5, 12);
    iconPath.cubicTo(22.0625, 12, 25, 14.9375, 25, 18.5);
    iconPath.cubicTo(25, 20.0312, 24.4688, 21.4375, 23.5625, 22.5625);
    iconPath.lineTo(27.75, 26.75);
    
    // Inner circle of magnifying glass
    iconPath.moveTo(13.5, 18.5);
    iconPath.cubicTo(13.5, 21.2812, 15.7188, 23.5, 18.5, 23.5);
    iconPath.cubicTo(21.25, 23.5, 23.5, 21.2812, 23.5, 18.5);
    iconPath.cubicTo(23.5, 15.75, 21.25, 13.5, 18.5, 13.5);
    iconPath.cubicTo(15.7188, 13.5, 13.5, 15.75, 13.5, 18.5);
    
    canvas.drawPath(iconPath, iconPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
