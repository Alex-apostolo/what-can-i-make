import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

class Database {
  static Future<sqflite.Database> initializeDatabase(
    String databaseName,
  ) async {
    final dbPath = await sqflite.getDatabasesPath();
    final path = join(dbPath, databaseName);

    return await sqflite.openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE ingredients(
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            quantity INTEGER NOT NULL,
            unit TEXT NOT NULL,
            category TEXT NOT NULL
          )
        ''');
      },
    );
  }
}
