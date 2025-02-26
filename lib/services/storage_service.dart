import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../services/openai_service.dart';

class StorageService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'kitchen_inventory.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE kitchen_items(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            category TEXT NOT NULL,
            quantity TEXT,
            notes TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          )
        ''');
      },
    );
  }

  static Future<StorageService> initialize() async {
    final service = StorageService();
    await service.database; // Ensure database is initialized
    return service;
  }

  Future<List<KitchenItem>> getInventory() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('kitchen_items');

    return List.generate(maps.length, (i) {
      return KitchenItem(
        name: maps[i]['name'],
        category: maps[i]['category'],
        quantity: maps[i]['quantity'],
        notes: maps[i]['notes'],
      );
    });
  }

  Future<void> addItems(List<KitchenItem> newItems) async {
    final db = await database;
    final batch = db.batch();

    for (final item in newItems) {
      // Check if item exists
      final List<Map<String, dynamic>> existing = await db.query(
        'kitchen_items',
        where: 'LOWER(name) = ? AND category = ?',
        whereArgs: [item.name.toLowerCase(), item.category],
      );

      if (existing.isEmpty) {
        // Insert new item
        batch.insert('kitchen_items', {
          'name': item.name,
          'category': item.category,
          'quantity': item.quantity,
          'notes': item.notes,
          'updated_at': DateTime.now().toIso8601String(),
        });
      } else {
        // Update existing item
        batch.update(
          'kitchen_items',
          {
            'quantity': item.quantity,
            'notes': item.notes,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'LOWER(name) = ? AND category = ?',
          whereArgs: [item.name.toLowerCase(), item.category],
        );
      }
    }

    await batch.commit();
  }

  Future<void> removeItem(KitchenItem item) async {
    final db = await database;
    await db.delete(
      'kitchen_items',
      where: 'LOWER(name) = ? AND category = ?',
      whereArgs: [item.name.toLowerCase(), item.category],
    );
  }

  Future<void> updateItem(KitchenItem updatedItem) async {
    final db = await database;
    await db.update(
      'kitchen_items',
      {
        'name': updatedItem.name,
        'category': updatedItem.category,
        'quantity': updatedItem.quantity,
        'notes': updatedItem.notes,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'LOWER(name) = ? AND category = ?',
      whereArgs: [updatedItem.name.toLowerCase(), updatedItem.category],
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
