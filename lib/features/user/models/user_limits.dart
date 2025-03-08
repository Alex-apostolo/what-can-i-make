/// Constants for user request limits
class UserLimits {
  /// Default number of API requests allowed per user
  static const int defaultRequestLimit = 50;

  /// Initial request count for new users
  static const int initialRequestCount = 0;

  // Private constructor to prevent instantiation
  UserLimits._();
}
