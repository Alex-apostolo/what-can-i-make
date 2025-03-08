/// Exception thrown when API request limits are exceeded
class ApiLimitExceededException implements Exception {
  final String message;
  
  ApiLimitExceededException([this.message = 'API request limit exceeded. Please upgrade your plan.']);
  
  @override
  String toString() => message;
} 