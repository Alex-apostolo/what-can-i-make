import 'package:dartz/dartz.dart';
import 'failures/failure.dart';

/// Global error handler for the application
class ErrorHandler {
  /// Function to show error messages to the user
  void Function(Failure) showError = (_) {};

  /// Handles a failure by showing an error message
  void handleFailure(Failure failure) {
    showError(failure);
  }

  /// Handles an Either result, executing success callback on Right
  /// or showing error on Left
  void handleEither<T>(
    Either<Failure, T> either, {
    required Function(T) onSuccess,
  }) {
    either.fold(handleFailure, onSuccess);
  }
}

/// Global instance of the error handler
final errorHandler = ErrorHandler();
