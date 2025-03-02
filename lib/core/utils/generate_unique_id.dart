import 'package:uuid/uuid.dart';

String generateUniqueId() {
  return Uuid().v4();
}

String generateUniqueIdWithTimestamp() {
  return DateTime.now().microsecondsSinceEpoch.toString() + Uuid().v4();
}

int getTimestampFromId(String id) {
  return int.parse(id.substring(0, 13));
}
