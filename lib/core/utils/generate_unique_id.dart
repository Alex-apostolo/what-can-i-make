import 'package:uuid/uuid.dart';

String generateUniqueId() {
  return Uuid().v4();
}
