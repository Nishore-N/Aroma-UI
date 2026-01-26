import 'dart:developer' as developer;

/// A utility class for logging messages with different severity levels.
class LoggerUtil {
  /// Log an error message with optional error and stack trace.
  static void error(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    String? name,
  }) {
    developer.log(
      message,
      name: name ?? 'Flavoryx',
      error: error,
      stackTrace: stackTrace,
      level: 1000, // Level.SEVERE
    );
  }

  /// Log an informational message.
  static void info(
    String message, {
    String? name,
  }) {
    developer.log(
      message,
      name: name ?? 'Flavoryx',
      level: 800, // Level.INFO
    );
  }

  /// Log a debug message.
  static void debug(
    String message, {
    String? name,
  }) {
    developer.log(
      message,
      name: name ?? 'Flavoryx',
      level: 500, // Level.FINE
    );
  }

  /// Log a verbose message.
  static void verbose(
    String message, {
    String? name,
  }) {
    developer.log(
      message,
      name: name ?? 'Flavoryx',
      level: 300, // Level.FINEST
    );
  }

  /// Log a warning message.
  static void warning(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    String? name,
  }) {
    developer.log(
      message,
      name: name ?? 'Flavoryx',
      error: error,
      stackTrace: stackTrace,
      level: 900, // Level.WARNING
    );
  }
}
