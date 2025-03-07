import 'package:uuid/uuid.dart';

int getTimestampFromId(String id) {
  return int.parse(id.substring(0, 10));
}

String generateTemporaryId() {
  return Uuid().v4();
}
