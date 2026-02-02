import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:aroma/ui/screens/auth/auth_wrapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Match the native splash background color to ensure seamless transition
      backgroundColor: const Color(0xFFFE734C), 
      body: Center(
        child: Lottie.asset(
          'assets/aroma_splash.json',
          controller: _controller,
          onLoaded: (composition) {
            // Configure the animation duration and start playing
            _controller
              ..duration = composition.duration
              ..forward().whenComplete(() {
                // Navigate to the main app after animation finishes
                Navigator.of(context).pushReplacement(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => const AuthWrapper(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                    transitionDuration: const Duration(milliseconds: 500),
                  ),
                );
              });
          },
          // Ensure the animation fills the screen appropriately if needed, 
          // or just stays centered as a logo.
          // Since the json has w:1080 h:1920, using contain ensures it fits entirely within the screen
          // regardless of aspect ratio, while the background color fills the rest.
          fit: BoxFit.contain, 
          alignment: Alignment.center,
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
        ),
      ),
    );
  }
}
