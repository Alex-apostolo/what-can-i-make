import 'package:flutter/material.dart';
import 'package:dartz/dartz.dart';
import '../failures/failure.dart';

extension ContextExtensions on BuildContext {
  /// Handles Either result with automatic error display via SnackBar
  ///
  /// [result] is the Either to handle
  /// [onSuccess] is called when the result is Right
  /// Returns the Right value if successful, null otherwise
  Future<T?> handleEither<T>({
    required Either<Failure, T> result,
    required Function(T) onSuccess,
    Color errorColor = Colors.red,
  }) async {
    result.fold((failure) {
      ScaffoldMessenger.of(this).showSnackBar(
        SnackBar(
          content: Text(failure.message),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }, (value) => onSuccess(value));
    return null;
  }
}
