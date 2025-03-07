import 'package:cloud_firestore/cloud_firestore.dart';

typedef AppDatabase = FirebaseFirestore;

class Database {
  static Future<AppDatabase> initializeDatabase() async {
    return FirebaseFirestore.instance;
  }
}
