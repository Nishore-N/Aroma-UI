// lib/data/services/app_state_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AppStateService {
  static const String _currentScreenKey = 'current_screen';
  static const String _screenDataKey = 'screen_data';
  static const String _timestampKey = 'state_timestamp';
  static const String _userSessionKey = 'user_session_active';

  // Save current app state when app goes to background
  static Future<void> saveAppState({
    required String currentScreen,
    Map<String, dynamic>? screenData,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save current screen and data
      await prefs.setString(_currentScreenKey, currentScreen);
      if (screenData != null) {
        await prefs.setString(_screenDataKey, jsonEncode(screenData));
      }
      
      // Save timestamp for expiration check
      await prefs.setString(_timestampKey, DateTime.now().toIso8601String());
      
      // Mark user session as active
      await prefs.setBool(_userSessionKey, true);
      
      print('💾 App state saved: $currentScreen');
    } catch (e) {
      print('Error saving app state: $e');
    }
  }

  // Get preserved app state
  static Future<Map<String, dynamic>?> getPreservedAppState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if state is recent (within 2 hours)
      final timestamp = prefs.getString(_timestampKey);
      if (timestamp == null) return null;
      
      final savedTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      
      // If state is older than 2 hours, don't restore
      if (now.difference(savedTime).inHours > 2) {
        print('⏰ App state expired (${now.difference(savedTime).inHours}h old)');
        await clearAppState();
        return null;
      }
      
      // Check if user session is still active
      final sessionActive = prefs.getBool(_userSessionKey) ?? false;
      if (!sessionActive) {
        print('🔒 User session not active');
        return null;
      }
      
      final currentScreen = prefs.getString(_currentScreenKey);
      final screenDataJson = prefs.getString(_screenDataKey);
      
      if (currentScreen == null) return null;
      
      Map<String, dynamic>? screenData;
      if (screenDataJson != null) {
        screenData = Map<String, dynamic>.from(jsonDecode(screenDataJson));
      }
      
      print('📂 App state restored: $currentScreen');
      
      return {
        'currentScreen': currentScreen,
        'screenData': screenData,
        'savedTime': savedTime,
      };
    } catch (e) {
      print('Error getting preserved app state: $e');
      return null;
    }
  }

  // Clear app state (when user logs out or app reset)
  static Future<void> clearAppState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentScreenKey);
      await prefs.remove(_screenDataKey);
      await prefs.remove(_timestampKey);
      await prefs.setBool(_userSessionKey, false);
      
      print('🗑️ App state cleared');
    } catch (e) {
      print('Error clearing app state: $e');
    }
  }

  // Mark user session as inactive (when app is fully closed)
  static Future<void> markSessionInactive() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_userSessionKey, false);
      print('🔒 User session marked inactive');
    } catch (e) {
      print('Error marking session inactive: $e');
    }
  }

  // Check if we should restore state (recent and valid)
  static Future<bool> shouldRestoreState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getString(_timestampKey);
      final sessionActive = prefs.getBool(_userSessionKey) ?? false;
      
      if (timestamp == null || !sessionActive) return false;
      
      final savedTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      
      // Only restore if within 2 hours and session is active
      return now.difference(savedTime).inHours < 2 && sessionActive;
    } catch (e) {
      print('Error checking restore state: $e');
      return false;
    }
  }

  // Get screen-specific data for restoration
  static Future<Map<String, dynamic>?> getScreenData(String screenName) async {
    try {
      final state = await getPreservedAppState();
      if (state == null) return null;
      
      return state['screenData'] as Map<String, dynamic>?;
    } catch (e) {
      print('Error getting screen data: $e');
      return null;
    }
  }
}
