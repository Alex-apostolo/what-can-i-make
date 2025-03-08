import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:logger/logger.dart';

/// A custom logger that extends Logger and integrates Firebase Crashlytics.
class AppLogger extends Logger {
  AppLogger({super.filter, LogPrinter? printer, super.output, super.level})
    : super(
        printer:
            printer ??
            PrettyPrinter(
              methodCount: 2, // Stack trace depth
              errorMethodCount: 8, // Stack trace depth for errors
              lineLength: 60, // Log line width
              colors: false, // Enable ANSI colors
              printEmojis: true, // Use emojis in logs
            ),
      );

  @override
  void log(
    Level level,
    dynamic message, {
    Object? error,
    StackTrace? stackTrace,
    DateTime? time,
  }) {
    // Call the original log method to retain all Logger functionality
    super.log(level, message, error: error, stackTrace: stackTrace, time: time);

    // Send warnings, errors, and fatal logs to Firebase Crashlytics in release mode
    if (!kDebugMode &&
        (level == Level.warning ||
            level == Level.error ||
            level == Level.fatal)) {
      _sendToCrashlytics(level, message, error, stackTrace);
    }
  }

  /// Send logs to Firebase Crashlytics (only in release mode)
  void _sendToCrashlytics(
    Level level,
    dynamic message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    String crashlyticsMessage = "[${level.name.toUpperCase()}] $message";
    FirebaseCrashlytics.instance.log(crashlyticsMessage);

    if (error != null) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: crashlyticsMessage,
        fatal: level == Level.fatal, // Mark fatal logs as fatal
      );
    }
  }
}
