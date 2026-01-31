import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import '../../../core/services/auth_service.dart';
import '../../../state/home_provider.dart';
import '../../../data/services/app_initialization_service.dart';
import '../../../data/services/splash_state_service.dart';
import '../../../data/services/app_state_service.dart';
import '../../../data/services/app_state_persistence_service.dart';

import '../auth/login_screen.dart';
import '../home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  final AuthService? authService;
  
  const SplashScreen({
    super.key,
    this.authService,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _initStatus = 'Initializing app...';
  double _progress = 0.0;
  
  // Dynamic engaging messages for different phases
  final List<String> _engagingMessages = [
    'Preparing your culinary journey...',
    'Discovering amazing recipes...',
    'Setting up your flavor experience...',
    'Almost ready to cook...',
    'Your kitchen awaits...',
  ];
  
  // Dynamic motivational messages
  final List<String> _motivationalMessages = [
    ' Cooking up something special...',
    ' Master chefs at work...',
    ' Crafting your perfect meal...',
    ' Your flavor adventure begins...',
    ' Something delicious is coming...',
  ];

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Development mode - fixed 5 second splash screen
      setState(() {
        _initStatus = 'Initializing app...';
        _progress = 0.2;
      });

      // Initialize auth service first
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.initialize();
      
      setState(() {
        _initStatus = 'Ready!';
        _progress = 1.0;
      });

      if (!mounted) return;

      // Simple auth check and navigation
      if (authService.isAuthenticated) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const HomeScreen(),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const LoginScreen(),
          ),
        );
      }

    } catch (e, stackTrace) {
      print('❌ App initialization failed: $e');
      print('Stack trace: $stackTrace');
      
      // Still navigate to app even if initialization fails
      if (!mounted) return;
      
      final authService = Provider.of<AuthService>(context, listen: false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => authService.isAuthenticated
              ? const HomeScreen()
              : const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Lottie animation only
          Container(
            width: double.infinity,
            height: double.infinity,
            child: Lottie.asset(
              'assets/aroma_splash.json',
              fit: BoxFit.fill,
            ),
          ),
        ],
      ),
    );
  }
}
