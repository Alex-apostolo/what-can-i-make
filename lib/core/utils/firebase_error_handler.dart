import 'package:cloud_firestore/cloud_firestore.dart' as firebase;

/// Utility class for handling Firebase errors
class FirebaseErrorHandler {
  /// Converts Firebase error codes to user-friendly messages
  static String getFriendlyErrorMessage(firebase.FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'You do not have permission to access this resource.';
      case 'unauthenticated':
        return 'You must be logged in to access this resource.';
      case 'unauthorized':
        return 'You are not authorized to access this resource.';
      case 'invalid-argument':
        return 'The request contains invalid arguments.';
      case 'resource-exhausted':
        return 'The resource has been exhausted.';
      case 'unavailable':
        return 'The service is currently unavailable.';
      case 'not-found':
        return 'The requested resource was not found.';
      case 'already-exists':
        return 'The resource already exists.';
      case 'cancelled':
        return 'The operation was cancelled.';
      case 'data-loss':
        return 'Unrecoverable data loss or corruption.';
      case 'deadline-exceeded':
        return 'Operation timed out.';
      case 'failed-precondition':
        return 'The operation was rejected because the system is not in a state required for the operation.';
      case 'internal':
        return 'Internal server error.';
      case 'out-of-range':
        return 'Operation was attempted past the valid range.';
      case 'unimplemented':
        return 'Operation is not implemented or not supported.';
      case 'unknown':
        return 'Unknown error occurred.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }
}
