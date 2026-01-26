// lib/data/services/splash_state_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SplashStateService {
  static const String _lastInitKey = 'last_initialization_time';
  static const String _lastInitDateKey = 'last_initialization_date';
  static const String _appStateKey = 'preserved_app_state';

  // Check if this is the first launch of the day
  static Future<bool> isFirstLaunchOfDay() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastInitDate = prefs.getString(_lastInitDateKey);
      
      final today = DateTime.now();
      final todayString = '${today.year}-${today.month}-${today.day}';
      
      if (lastInitDate == null || lastInitDate != todayString) {
        // First launch of the day
        await prefs.setString(_lastInitDateKey, todayString);
        await prefs.setString(_lastInitKey, today.toIso8601String());
        print('📅 First launch of the day: $todayString');
        return true;
      }
      
      print('📅 Same day launch detected: $todayString');
      return false;
    } catch (e) {
      print('Error checking first launch of day: $e');
      return true; // Default to full initialization on error
    }
  }

  // Get the time since last initialization
  static Future<Duration> getTimeSinceLastInit() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastInitTime = prefs.getString(_lastInitKey);
      
      if (lastInitTime == null) {
        return Duration(days: 1); // Very long duration to indicate first time
      }
      
      final lastInit = DateTime.parse(lastInitTime);
      final now = DateTime.now();
      return now.difference(lastInit);
    } catch (e) {
      print('Error getting time since last init: $e');
      return Duration(days: 1);
    }
  }

  // Check if full initialization is needed (more than 12 hours since last init)
  static Future<bool> needsFullInitialization() async {
    final timeSinceLastInit = await getTimeSinceLastInit();
    final isFirstLaunch = await isFirstLaunchOfDay();
    
    // Full init needed if:
    // 1. First launch of the day, OR
    // 2. More than 12 hours since last full initialization
    return isFirstLaunch || timeSinceLastInit.inHours > 12;
  }

  // Save app state for preservation
  static Future<void> preserveAppState(Map<String, dynamic> state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_appStateKey, jsonEncode(state));
      print('💾 App state preserved');
    } catch (e) {
      print('Error preserving app state: $e');
    }
  }

  // Get preserved app state
  static Future<Map<String, dynamic>?> getPreservedAppState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateJson = prefs.getString(_appStateKey);
      
      if (stateJson != null) {
        final state = Map<String, dynamic>.from(jsonDecode(stateJson));
        print('📂 App state restored');
        return state;
      }
      
      return null;
    } catch (e) {
      print('Error getting preserved app state: $e');
      return null;
    }
  }

  // Clear preserved state (when user logs out or app reset)
  static Future<void> clearPreservedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_appStateKey);
      print('🗑️ Preserved app state cleared');
    } catch (e) {
      print('Error clearing preserved app state: $e');
    }
  }

  // Get initialization duration based on time since last init
  static Duration getInitializationDuration() {
    // For same-day launches: 3-5 seconds max
    // For first-day launches: 10-20 seconds
    return const Duration(seconds: 3);
  }
}
