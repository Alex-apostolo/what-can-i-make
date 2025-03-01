/// Base class for all failures in the application
abstract class Failure {
  final String message;

  const Failure(this.message);
}

/// Failure related to OpenAI API requests
class OpenAIRequestFailure extends Failure {
  const OpenAIRequestFailure(String message) : super('OpenAI request failed: $message');
}

/// Failure when OpenAI returns an empty response
class OpenAIEmptyResponseFailure extends Failure {
  const OpenAIEmptyResponseFailure() : super('OpenAI returned an empty response');
}

/// Failure when connection to OpenAI fails
class OpenAIConnectionFailure extends Failure {
  const OpenAIConnectionFailure() : super('Failed to connect to OpenAI API');
}

/// Failure when parsing OpenAI response
class ParsingFailure extends Failure {
  final String content;

  const ParsingFailure(String message, this.content) : super('Parsing error: $message');
}

/// Failure when database connection fails
class DatabaseConnectionFailure extends Failure {
  const DatabaseConnectionFailure() : super('Failed to connect to database');
}

/// Failure when a database query fails
class DatabaseQueryFailure extends Failure {
  const DatabaseQueryFailure(String operation, String error)
      : super('Database $operation failed: $error');
}

/// Failure when an item is not found in the database
class ItemNotFoundFailure extends Failure {
  const ItemNotFoundFailure(String id) : super('Item with ID $id not found');
} 