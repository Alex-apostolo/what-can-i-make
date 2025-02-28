import 'package:dartz/dartz.dart';
import '../failures/failure.dart';

/// Global error handler for the application
class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  /// Function to show errors (can be set from UI layer)
  void Function(Failure failure)? showError;

  /// Process Either result and handle errors automatically
  T? handleEither<T>(Either<Failure, T> result, {Function(T)? onSuccess}) {
    return result.fold(
      (failure) {
        if (showError != null) {
          showError!(failure);
        }
        return null;
      },
      (value) {
        if (onSuccess != null) {
          onSuccess(value);
        }
        return value;
      },
    );
  }
}

/// Singleton instance for easy access
final errorHandler = ErrorHandler();
