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
  handleEither<T>(Either<Failure, T> either) {
    return either.fold((failure) {
      handleFailure(failure);
      return null;
    }, (value) => value);
  }
}

/// Global instance of the error handler
final errorHandler = ErrorHandler();
