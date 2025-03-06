import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'failures/failure.dart';
import 'package:what_can_i_make/core/utils/logger.dart';

class ErrorHandler {
  final GlobalKey<NavigatorState> navigatorKey;
  final AppLogger _logger = AppLogger();

  ErrorHandler({required this.navigatorKey});

  /// Function to show error messages to the user
  void showError(Failure failure) {
    final context = navigatorKey.currentContext;

    _logger.e('Failure occurred', error: failure);

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

  /// Handles a failure by showing an error message
  void handleFailure(Failure failure) {
    showError(failure);
  }

  /// Handles an Either result, executing success callback on Right
  /// or showing error on Left
  handleEither<T>(Either<Failure, T> either) {
    return either.fold((failure) {
      handleFailure(failure);
      return null;
    }, (value) => value);
  }
}
