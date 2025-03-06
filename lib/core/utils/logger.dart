import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Log levels for the application
enum LogLevel {
  verbose,
  debug,
  info,
  warning,
  error,
  wtf, // What a Terrible Failure
  nothing, // No logs
}

/// A centralized logging utility for the application
class Logger {
  /// The tag used to identify logs from this class
  final String tag;

  /// The minimum log level to display
  static LogLevel _minLevel = kDebugMode ? LogLevel.verbose : LogLevel.info;

  /// Whether to show timestamps in logs
  static bool _showTimestamps = true;

  /// Whether to show log levels in logs
  static bool _showLogLevels = true;

  /// Whether to show tags in logs
  static bool _showTags = true;

  /// Whether to send logs to Crashlytics
  static bool _sendToCrashlytics = !kDebugMode;

  /// Create a new logger with the specified tag
  Logger(this.tag);

  /// Configure the logger settings
  static void configure({
    LogLevel? minLevel,
    bool? showTimestamps,
    bool? showLogLevels,
    bool? showTags,
    bool? sendToCrashlytics,
  }) {
    if (minLevel != null) _minLevel = minLevel;
    if (showTimestamps != null) _showTimestamps = showTimestamps;
    if (showLogLevels != null) _showLogLevels = showLogLevels;
    if (showTags != null) _showTags = showTags;
    if (sendToCrashlytics != null) _sendToCrashlytics = sendToCrashlytics;
  }

  /// Format a log message with the appropriate prefixes
  String _formatMessage(LogLevel level, String message) {
    final StringBuffer buffer = StringBuffer();

    // Add timestamp if enabled
    if (_showTimestamps) {
      buffer.write('[${DateTime.now().toIso8601String()}] ');
    }

    // Add log level if enabled
    if (_showLogLevels) {
      buffer.write('[${level.name.toUpperCase()}] ');
    }

    // Add tag if enabled
    if (_showTags) {
      buffer.write('[$tag] ');
    }

    // Add the message
    buffer.write(message);

    return buffer.toString();
  }

  /// Log a message if the level is sufficient
  void _log(
    LogLevel level,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    // Skip if this log level is below the minimum
    if (level.index < _minLevel.index) return;

    final formattedMessage = _formatMessage(level, message);

    // Use different colors for different log levels
    Color? color;
    switch (level) {
      case LogLevel.verbose:
        color = Colors.grey;
        break;
      case LogLevel.debug:
        color = Colors.blue;
        break;
      case LogLevel.info:
        color = Colors.green;
        break;
      case LogLevel.warning:
        color = Colors.orange;
        break;
      case LogLevel.error:
      case LogLevel.wtf:
        color = Colors.red;
        break;
      default:
        color = null;
    }

    // Log to console with color if in debug mode
    if (kDebugMode) {
      final colorCode = color != null ? _ansiColorCode(color) : '';
      final resetCode = color != null ? '\x1B[0m' : '';

      if (error != null) {
        debugPrint('$colorCode$formattedMessage\nError: $error$resetCode');
        if (stackTrace != null) {
          debugPrint('$colorCode$stackTrace$resetCode');
        }
      } else {
        debugPrint('$colorCode$formattedMessage$resetCode');
      }
    }

    // Also log to dart:developer for more detailed logs in DevTools
    developer.log(
      message,
      name: tag,
      level: level.index * 100, // Convert our levels to developer.log levels
      error: error,
      stackTrace: stackTrace,
    );

    // Send to Crashlytics for warning and above
    if (_sendToCrashlytics && level.index >= LogLevel.warning.index) {
      _logToCrashlytics(level, message, error, stackTrace);
    }
  }

  /// Log to Firebase Crashlytics
  void _logToCrashlytics(
    LogLevel level,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    try {
      final crashlytics = FirebaseCrashlytics.instance;

      // Add a custom log
      crashlytics.log('[$tag] $message');

      // For errors and wtf, record as a non-fatal exception
      if (level == LogLevel.error || level == LogLevel.wtf) {
        crashlytics.recordError(
          error ?? message,
          stackTrace,
          reason: '[$tag] $message',
          fatal: level == LogLevel.wtf, // Mark wtf as fatal
        );
      }
    } catch (e) {
      // Fail silently if Crashlytics isn't available
      if (kDebugMode) {
        debugPrint('Failed to log to Crashlytics: $e');
      }
    }
  }

  /// Convert a Flutter Color to an ANSI color code for terminal output
  String _ansiColorCode(Color color) {
    // Simplified conversion - just using basic ANSI colors
    if (color == Colors.red) return '\x1B[31m';
    if (color == Colors.green) return '\x1B[32m';
    if (color == Colors.orange || color == Colors.amber) return '\x1B[33m';
    if (color == Colors.blue) return '\x1B[34m';
    if (color == Colors.grey) return '\x1B[37m';
    return '\x1B[0m'; // Default/reset
  }

  /// Log a verbose message
  void v(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.verbose, message, error, stackTrace);
  }

  /// Log a debug message
  void d(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.debug, message, error, stackTrace);
  }

  /// Log an info message
  void i(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.info, message, error, stackTrace);
  }

  /// Log a warning message
  void w(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.warning, message, error, stackTrace);
  }

  /// Log an error message
  void e(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.error, message, error, stackTrace);
  }

  /// Log a "what a terrible failure" message
  void wtf(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.wtf, message, error, stackTrace);
  }
}
