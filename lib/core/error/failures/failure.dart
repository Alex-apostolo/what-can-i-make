/// Base class for all failures in the application
abstract class Failure {
  final String message;

  const Failure(this.message);
}

class GenericFailure extends Failure {
  const GenericFailure()
    : super('An unexpected error occurred. Please try again.');
}

/// Failure related to OpenAI API requests
class OpenAIRequestFailure extends Failure {
  const OpenAIRequestFailure() : super('OpenAI request failed');
}

/// Failure when OpenAI returns an empty response
class OpenAIEmptyResponseFailure extends Failure {
  const OpenAIEmptyResponseFailure()
    : super('OpenAI returned an empty response');
}

/// Failure when connection to OpenAI fails
class OpenAIConnectionFailure extends Failure {
  const OpenAIConnectionFailure() : super('Failed to connect to OpenAI API');
}

/// Failure when parsing OpenAI response
class ParsingFailure extends Failure {
  const ParsingFailure() : super('Parsing error');
}

/// Failure when a database query fails
class DatabaseQueryFailure extends Failure {
  const DatabaseQueryFailure(super.message);
}

/// Failure when an item is not found in the database
class ItemNotFoundFailure extends Failure {
  const ItemNotFoundFailure(String id) : super('Item with ID $id not found');
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}
