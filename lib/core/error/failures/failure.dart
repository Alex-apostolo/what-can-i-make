import 'package:what_can_i_make/core/utils/logger.dart';

/// Base class for all failures in the application
abstract class Failure {
  /// User-friendly message to display to the user
  final String message;

  /// Detailed error information for logging (not shown to users)
  final Exception? error;

  /// Creates a new Failure with a user-friendly message and optional error details
  const Failure(this.message, this.error);

  /// Log this failure to the application logger
  void log() {
    final logger = AppLogger();
    logger.e(error?.toString() ?? message, error: error);
  }
}

/// Failure that occurs when a database query fails
class DatabaseQueryFailure extends Failure {
  /// Creates a new DatabaseQueryFailure with a message and optional error details
  const DatabaseQueryFailure(super.message, super.error);
}

/// Generic failure for unexpected errors
class GenericFailure extends Failure {
  /// Creates a generic failure with a default message and optional error details
  const GenericFailure(Exception error)
    : super('An unexpected error occurred. Please try again.', error);
}

/// Failure related to OpenAI API requests
class OpenAIRequestFailure extends Failure {
  /// Creates a new OpenAIRequestFailure with optional error details
  const OpenAIRequestFailure(Exception error)
    : super('OpenAI request failed', error);
}

/// Failure when OpenAI returns an empty response
class OpenAIEmptyResponseFailure extends Failure {
  /// Creates a new OpenAIEmptyResponseFailure with optional error details
  const OpenAIEmptyResponseFailure(Exception error)
    : super('OpenAI returned an empty response', error);
}

/// Failure when connection to OpenAI fails
class OpenAIConnectionFailure extends Failure {
  /// Creates a new OpenAIConnectionFailure with optional error details
  const OpenAIConnectionFailure(Exception error)
    : super('Failed to connect to OpenAI API', error);
}

/// Failure when parsing OpenAI response
class ParsingFailure extends Failure {
  /// Creates a new ParsingFailure with optional error details
  const ParsingFailure(Exception error) : super('Parsing error', error);
}

/// Failure when an item is not found in the database
class ItemNotFoundFailure extends Failure {
  /// Creates a new ItemNotFoundFailure with the ID of the item that wasn't found
  const ItemNotFoundFailure(String id, Exception error)
    : super('Item with ID $id not found', error);
}
