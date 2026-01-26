import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppStatePersistenceService {
  static bool _isInitialized = false;
  static SharedPreferences? _prefs;
  
  // State keys
  static const String _appStateKey = 'app_state';
  static const String _lastActiveTimeKey = 'last_active_time';
  
  // App lifecycle state
  static bool _isAppInBackground = false;
  static DateTime? _lastActiveTime;

  /// Initialize the service
  static Future<void> initialize() async {
    if (!_isInitialized) {
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;
      
      // Load persisted state
      await _loadPersistedState();
      
      if (kDebugMode) {
        print('✅ App State Persistence Service initialized');
        print('📊 [AppState] Last active: $_lastActiveTime');
      }
    }
  }

  /// Load persisted state from SharedPreferences
  static Future<void> _loadPersistedState() async {
    try {
      // Load last active time
      final lastActiveTimeStr = _prefs?.getString(_lastActiveTimeKey);
      if (lastActiveTimeStr != null) {
        _lastActiveTime = DateTime.parse(lastActiveTimeStr);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AppState] Error loading persisted state: $e');
      }
    }
  }

  /// Save current state to persistence
  static Future<void> saveState() async {
    try {
      if (_prefs == null) return;

      // Update last active time
      _lastActiveTime = DateTime.now();
      await _prefs!.setString(_lastActiveTimeKey, _lastActiveTime!.toIso8601String());

      // Update app state
      final appState = {
        'last_active_time': _lastActiveTime!.toIso8601String(),
        'app_in_background': _isAppInBackground,
      };

      await _prefs!.setString(_appStateKey, jsonEncode(appState));

      if (kDebugMode) {
        print('💾 [AppState] State saved successfully');
      }

    } catch (e) {
      if (kDebugMode) {
        print('❌ [AppState] Error saving state: $e');
      }
    }
  }

  /// Handle app lifecycle changes
  static void handleAppLifecycleChange(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _isAppInBackground = true;
        if (kDebugMode) {
          print('⏸️ [AppState] App went to background');
        }
        break;
      case AppLifecycleState.resumed:
        _isAppInBackground = false;
        if (kDebugMode) {
          print('▶️ [AppState] App resumed');
        }
        break;
      case AppLifecycleState.detached:
        _isAppInBackground = false;
        if (kDebugMode) {
          print('🔌 [AppState] App detached');
        }
        break;
      default:
        break;
    }
  }

  /// Check if full initialization is needed
  static bool needsFullInitialization() {
    if (_lastActiveTime == null) {
      return true; // First time launch
    }

    final now = DateTime.now();
    final timeSinceLastActive = now.difference(_lastActiveTime!);

    // Need full initialization if more than 2 hours away
    return timeSinceLastActive.inHours >= 2;
  }

  /// Get cache statistics
  static Map<String, dynamic> getCacheStats() {
    return {
      'service': 'App State Persistence Service',
      'last_active_time': _lastActiveTime?.toIso8601String(),
      'app_in_background': _isAppInBackground,
      'needs_full_init': needsFullInitialization(),
    };
  }

  /// Clear all persisted state
  static Future<void> clearPersistedState() async {
    try {
      if (_prefs != null) {
        await _prefs!.remove(_appStateKey);
        await _prefs!.remove(_lastActiveTimeKey);
      }

      _lastActiveTime = null;

      if (kDebugMode) {
        print('🗑️ [AppState] All persisted state cleared');
      }

    } catch (e) {
      if (kDebugMode) {
        print('❌ [AppState] Error clearing persisted state: $e');
      }
    }
  }

  /// Get initialization status
  static Map<String, dynamic> getInitializationStatus() {
    final now = DateTime.now();
    final timeSinceLastActive = _lastActiveTime != null 
        ? now.difference(_lastActiveTime!)
        : Duration.zero;

    return {
      'is_initialized': _isInitialized,
      'last_active_time': _lastActiveTime?.toIso8601String(),
      'time_since_last_active': {
        'days': timeSinceLastActive.inDays,
        'hours': timeSinceLastActive.inHours,
        'minutes': timeSinceLastActive.inMinutes,
        'seconds': timeSinceLastActive.inSeconds,
      },
      'app_in_background': _isAppInBackground,
      'needs_full_init': needsFullInitialization(),
    };
  }
}
