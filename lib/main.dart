// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// State & Services
import 'package:aroma/state/pantry_state.dart';
import 'package:aroma/state/home_provider.dart';
import 'package:aroma/data/services/shopping_list_service.dart';
import 'package:aroma/core/services/auth_service.dart';
import 'package:aroma/data/services/app_state_service.dart';
import 'package:aroma/data/services/app_state_persistence_service.dart';

// UI Screens
import 'package:aroma/ui/screens/auth/auth_wrapper.dart';
import 'package:aroma/ui/screens/intro/splash_screen.dart';

// Theme
import 'package:aroma/core/theme/app_theme.dart';
import 'package:aroma/core/utils/item_image_resolver.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Load environment variables
    await dotenv.load(fileName: ".env");


    // Initialize AuthService
    final authService = AuthService();

    // Initialize local asset resolver for pantry images
    await ItemImageResolver.init();

    // Mark session as inactive (app starting fresh)
    await AppStateService.markSessionInactive();

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthService>(
            create: (_) => authService..initialize(),
          ),
          ChangeNotifierProvider(create: (_) => ShoppingListService()),
          ChangeNotifierProvider(create: (_) => PantryState()..loadPantry()),
          ChangeNotifierProvider(create: (_) => HomeProvider()),
        ],
        child: MyApp(
          authService: authService,
        ),
      ),
    );
  } catch (e, stackTrace) {
    debugPrint('Error during app initialization: $e');
    debugPrint('Stack trace: $stackTrace');

    runApp(
      const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  final AuthService authService;
  
  const MyApp({
    super.key,
    required this.authService,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Handle app lifecycle with state persistence
    AppStatePersistenceService.handleAppLifecycleChange(state);
    
    switch (state) {
      case AppLifecycleState.paused:
        // App going to background - save current state
        _saveCurrentAppState();
        break;
      case AppLifecycleState.detached:
        // App being closed - mark session inactive, save final state, and clear session cache
        AppStateService.markSessionInactive();
        AppStatePersistenceService.saveState();
        
        
        if (kDebugMode) {
          print('🔌 [App Lifecycle] App detached - session cache cleared');
        }
        break;
      case AppLifecycleState.resumed:
        // App coming to foreground - session becomes active
        _markSessionActive();
        break;
      case AppLifecycleState.inactive:
        // App losing focus
        break;
      case AppLifecycleState.hidden:
        // App hidden
        break;
    }
  }

  Future<void> _saveCurrentAppState() async {
    try {
      // Save current state using persistence service
      await AppStatePersistenceService.saveState();
      
      // Get current route information for additional context
      final navKey = navigatorKey;
      if (navKey.currentContext != null) {
        final route = ModalRoute.of(navKey.currentContext!);
        if (route != null) {
          final screenName = route.settings.name ?? 'unknown';
          
          // Save basic state - you can extend this with more specific data
          await AppStateService.saveAppState(
            currentScreen: screenName,
            screenData: {
              'timestamp': DateTime.now().toIso8601String(),
            },
          );
        }
      }
    } catch (e) {
      debugPrint('Error saving app state on pause: $e');
    }
  }

  Future<void> _markSessionActive() async {
    try {
      // This will be handled by individual screens when they load
      print(' App resumed - session active');
      
      // Update persistence service for resumed state
      await AppStatePersistenceService.saveState();
    } catch (e) {
      debugPrint('Error marking session active: $e');
    }
  }

  // Global navigator key for state tracking
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Aroma Chefs',
      debugShowCheckedModeBanner: false,

      theme: AppTheme.lightTheme,

      home: const SplashScreen(),

      // 🔁 Used internally after splash
      routes: {
        '/auth': (_) => const AuthWrapper(),
      },
    );
  }
}