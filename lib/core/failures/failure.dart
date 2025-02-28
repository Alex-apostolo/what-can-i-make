/// Base class for all failures in the application
abstract class Failure {
  final String message;

  const Failure(this.message);

  @override
  String toString() => message;
}

/// Failures related to OpenAI service
abstract class OpenAIFailure extends Failure {
  const OpenAIFailure(String message) : super(message);
}

class OpenAIConnectionFailure extends OpenAIFailure {
  const OpenAIConnectionFailure() : super('No internet connection');
}

class OpenAIEmptyResponseFailure extends OpenAIFailure {
  const OpenAIEmptyResponseFailure() : super('Empty response from OpenAI');
}

class OpenAIRequestFailure extends OpenAIFailure {
  const OpenAIRequestFailure(String details)
    : super('Failed to analyze image: $details');
}

/// Failures related to parsing data
class ParsingFailure extends Failure {
  final String content;

  const ParsingFailure(String message, this.content) : super(message);
}

/// Failures related to storage operations
abstract class StorageFailure extends Failure {
  const StorageFailure(String message) : super(message);
}

class DatabaseConnectionFailure extends StorageFailure {
  const DatabaseConnectionFailure() : super('Failed to connect to database');
}

class ItemNotFoundFailure extends StorageFailure {
  final String itemId;

  const ItemNotFoundFailure(this.itemId) : super('Item not found: $itemId');
}

class DatabaseQueryFailure extends StorageFailure {
  final String operation;

  const DatabaseQueryFailure(this.operation, String details)
    : super('Database $operation failed: $details');
}
