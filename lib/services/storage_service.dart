import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/kitchen_item.dart';
import 'package:dartz/dartz.dart';
import '../core/failures/failure.dart';

class StorageService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'kitchen_inventory.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE items(
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            category TEXT NOT NULL,
            quantity TEXT,
            notes TEXT
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

  Future<Either<Failure, List<KitchenItem>>> getInventory() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('items');
      final items = List.generate(
        maps.length,
        (i) => KitchenItem.fromMap(maps[i]),
      );
      return Right(items);
    } catch (e) {
      return Left(StorageFailure('Failed to get inventory: ${e.toString()}'));
    }
  }

  Future<Either<Failure, Unit>> addItem(KitchenItem item) async {
    try {
      final db = await database;
      await db.insert(
        'items',
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return Right(unit);
    } catch (e) {
      return Left(StorageFailure('Failed to add item: ${e.toString()}'));
    }
  }

  Future<Either<Failure, Unit>> addItems(List<KitchenItem> items) async {
    try {
      final db = await database;
      final batch = db.batch();
      for (final item in items) {
        batch.insert(
          'items',
          item.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit();
      return Right(unit);
    } catch (e) {
      return Left(StorageFailure('Failed to add items: ${e.toString()}'));
    }
  }

  Future<Either<Failure, Unit>> updateItem(KitchenItem item) async {
    try {
      final db = await database;
      await db.update(
        'items',
        item.toMap(),
        where: 'id = ?',
        whereArgs: [item.id],
      );
      return Right(unit);
    } catch (e) {
      return Left(StorageFailure('Failed to update item: ${e.toString()}'));
    }
  }

  Future<Either<Failure, Unit>> removeItem(KitchenItem item) async {
    try {
      final db = await database;
      await db.delete('items', where: 'id = ?', whereArgs: [item.id]);
      return Right(unit);
    } catch (e) {
      return Left(StorageFailure('Failed to remove item: ${e.toString()}'));
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
