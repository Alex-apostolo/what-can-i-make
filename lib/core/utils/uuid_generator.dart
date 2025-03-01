import 'package:uuid/uuid.dart';

/// Utility class for generating UUIDs
class UuidGenerator {
  static final _uuid = Uuid();
  
  /// Generates a new UUID v4
  static String generate() {
    return _uuid.v4();
  }
} 