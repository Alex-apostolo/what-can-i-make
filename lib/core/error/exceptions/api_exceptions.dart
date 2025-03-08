/// Exception thrown when API request limits are exceeded
class ApiLimitExceededException implements Exception {
  final String message;

  ApiLimitExceededException([
    this.message = 'You\'ve run out of AI credits. Purchase more to continue.',
  ]);

  @override
  String toString() => message;
}
