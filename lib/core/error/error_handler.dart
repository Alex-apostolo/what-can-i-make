import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'failures/failure.dart';
import 'package:what_can_i_make/core/utils/logger.dart';

class ErrorHandler {
  final GlobalKey<NavigatorState> navigatorKey;
  final AppLogger _logger = AppLogger();

  ErrorHandler({required this.navigatorKey});

  /// Function to show error messages to the user
  void showErrorSnackbar(Failure failure) {
    final context = navigatorKey.currentContext;

    // Log the failure with detailed error information
    failure.log();

    if (context == null) {
      _logger.w("Context is null, cannot show error snackbar");
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(failure.message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.fixed,
      ),
    );
  }

  /// Shows a fatal error dialog that blocks the UI until user takes action
  void showFatalErrorDialog(Failure failure, {VoidCallback? onRetry}) {
    final context = navigatorKey.currentContext;

    // Log the failure with detailed error information
    failure.log();

    if (context == null) {
      _logger.w("Context is null, cannot show fatal error dialog");
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false, // User must tap button to dismiss
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.red[100],
          title: const Text('Fatal Error', style: TextStyle(color: Colors.red)),
          content: SingleChildScrollView(
            child: Text(
              failure.message,
              style: const TextStyle(color: Colors.red),
            ),
          ),
          actions: <Widget>[
            if (onRetry != null)
              TextButton(
                child: const Text('Retry', style: TextStyle(color: Colors.red)),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  onRetry();
                },
              ),
          ],
        );
      },
    );
  }

  /// Handles a failure by showing an error message
  void handleFailure(Failure failure) {
    showErrorSnackbar(failure);
  }

  /// Handles a fatal failure that prevents the app from continuing normal operation
  void handleFatalFailure(Failure failure, {VoidCallback? onRetry}) {
    showFatalErrorDialog(failure, onRetry: onRetry);
  }

  /// Handles an Either result, executing success callback on Right
  /// or showing error on Left
  handleEither<T>(Either<Failure, T> either) {
    return either.fold((failure) {
      handleFailure(failure);
      return null;
    }, (value) => value);
  }

  /// Handles an Either result for operations where failure is fatal
  handleFatalEither<T>(Either<Failure, T> either, {VoidCallback? onRetry}) {
    return either.fold((failure) {
      handleFatalFailure(failure, onRetry: onRetry);
      return null;
    }, (value) => value);
  }
}
