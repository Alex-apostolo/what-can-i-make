/// Base class for all failures in the application
abstract class Failure {
  final String message;

  const Failure(this.message);

  @override
  String toString() => message;
}

/// Failures related to OpenAI service
class OpenAIFailure extends Failure {
  const OpenAIFailure(String message) : super(message);
}

/// Failures related to storage operations
class StorageFailure extends Failure {
  const StorageFailure(String message) : super(message);
}

/// Failures related to parsing data
class ParsingFailure extends Failure {
  const ParsingFailure(String message) : super(message);
}
