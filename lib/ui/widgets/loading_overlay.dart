import 'package:flutter/material.dart';

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final double opacity;
  final Color color;
  final Widget progressIndicator;

  const LoadingOverlay({
    Key? key,
    required this.isLoading,
    required this.child,
    this.opacity = 0.5,
    this.color = Colors.black,
    this.progressIndicator = const CircularProgressIndicator(),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: color.withOpacity(opacity),
            child: Center(
              child: progressIndicator,
            ),
          ),
      ],
    );
  }
}
