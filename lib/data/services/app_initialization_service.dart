import 'package:flutter/foundation.dart';
import '../../state/pantry_state.dart';
import '../../state/home_provider.dart';
import '../services/preference_api_service.dart';

class AppInitializationService {
  static bool _initialized = false;
  static final Map<String, dynamic> _initStats = {};

  /// Initialize all app services during splash screen
  static Future<Map<String, dynamic>> initializeDuringSplash() async {
    if (_initialized) {
      return _initStats;
    }

    final stopwatch = Stopwatch()..start();
    _initStats.clear();

    try {
      debugPrint('🚀 Starting app initialization...');

      // Phase 1: Critical Services (0-2 seconds)
      await _initializeCriticalServices();
      
      stopwatch.stop();
      _initStats['totalTime'] = stopwatch.elapsedMilliseconds;
      _initStats['success'] = true;
      _initialized = true;

      debugPrint('✅ App initialization completed in ${stopwatch.elapsedMilliseconds}ms');
      return _initStats;

    } catch (e, stackTrace) {
      stopwatch.stop();
      _initStats['totalTime'] = stopwatch.elapsedMilliseconds;
      _initStats['success'] = false;
      _initStats['error'] = e.toString();
      
      debugPrint('❌ App initialization failed: $e');
      debugPrint('Stack trace: $stackTrace');
      
      return _initStats;
    }
  }

  /// Phase 1: Initialize critical services that must complete before app starts
  static Future<void> _initializeCriticalServices() async {
    final phaseStopwatch = Stopwatch()..start();
    
    try {
      debugPrint('📋 Phase 1: Critical Services');
      
      // 1. Cache Manager (already done in main.dart, but verify)
      // Note: CacheManagerService might be removed or simplified later
      // For now, we keep the initialization if it's still needed for other things
      
      phaseStopwatch.stop();
      _initStats['phase1Time'] = phaseStopwatch.elapsedMilliseconds;
      
      debugPrint('✅ Phase 1 completed in ${phaseStopwatch.elapsedMilliseconds}ms');
      
    } catch (e) {
      phaseStopwatch.stop();
      _initStats['phase1Time'] = phaseStopwatch.elapsedMilliseconds;
      _initStats['phase1Error'] = e.toString();
      debugPrint('❌ Phase 1 failed: $e');
      rethrow;
    }
  }

  /// Get initialization statistics
  static Map<String, dynamic> get initStats => Map.from(_initStats);

  /// Check if initialization is complete
  static bool get isInitialized => _initialized;

  /// Reset initialization state (for testing)
  static void reset() {
    _initialized = false;
    _initStats.clear();
  }

  /// Get recommended splash duration based on initialization progress
  static Duration getRecommendedSplashDuration() {
    if (!_initStats.containsKey('totalTime')) {
      return const Duration(seconds: 3); // Reduced default
    }
    
    final totalTime = _initStats['totalTime'] as int;
    final baseDuration = Duration(milliseconds: totalTime);
    
    // Add 1 second buffer for smooth transition
    return baseDuration + const Duration(seconds: 1);
  }
}
