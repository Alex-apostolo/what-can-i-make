import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/kitchen_item.dart';
import 'package:dartz/dartz.dart';
import '../core/failures/failure.dart';

class StorageService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    try {
      _database = await _initDB();
      return _database!;
    } on DatabaseException catch (_) {
      throw DatabaseConnectionFailure();
    } catch (e) {
      throw DatabaseConnectionFailure();
    }
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'kitchen_inventory.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE items(
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            category TEXT NOT NULL,
            quantity INTEGER
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Drop notes column and convert quantity to INTEGER
          await db.execute('ALTER TABLE items RENAME TO items_old');
          await db.execute('''
            CREATE TABLE items(
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              category TEXT NOT NULL,
              quantity INTEGER
            )
          ''');
          await db.execute('''
            INSERT INTO items (id, name, category, quantity)
            SELECT id, name, category, CAST(quantity AS INTEGER)
            FROM items_old
          ''');
          await db.execute('DROP TABLE items_old');
        }
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
    } on DatabaseException catch (e) {
      return Left(DatabaseQueryFailure('query', e.toString()));
    } on FormatException catch (e) {
      return Left(DatabaseQueryFailure('query', 'Format error: ${e.message}'));
    } catch (e) {
      return Left(DatabaseQueryFailure('query', e.toString()));
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
    } on DatabaseException catch (e) {
      return Left(DatabaseQueryFailure('insert', e.toString()));
    } catch (e) {
      return Left(DatabaseQueryFailure('insert', e.toString()));
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
    } on DatabaseException catch (e) {
      return Left(DatabaseQueryFailure('batch insert', e.toString()));
    } catch (e) {
      return Left(DatabaseQueryFailure('batch insert', e.toString()));
    }
  }

  Future<Either<Failure, Unit>> updateItem(KitchenItem item) async {
    try {
      final db = await database;
      final count = await db.update(
        'items',
        item.toMap(),
        where: 'id = ?',
        whereArgs: [item.id],
      );

      if (count == 0) {
        return Left(ItemNotFoundFailure(item.id));
      }

      return Right(unit);
    } on DatabaseException catch (e) {
      return Left(DatabaseQueryFailure('update', e.toString()));
    } catch (e) {
      return Left(DatabaseQueryFailure('update', e.toString()));
    }
  }

  Future<Either<Failure, Unit>> removeItem(KitchenItem item) async {
    try {
      final db = await database;
      final count = await db.delete(
        'items',
        where: 'id = ?',
        whereArgs: [item.id],
      );

      if (count == 0) {
        return Left(ItemNotFoundFailure(item.id));
      }

      return Right(unit);
    } on DatabaseException catch (e) {
      return Left(DatabaseQueryFailure('delete', e.toString()));
    } catch (e) {
      return Left(DatabaseQueryFailure('delete', e.toString()));
    }
  }

  Future<Either<Failure, Unit>> clearInventory() async {
    try {
      final db = await database;
      await db.delete('items');
      return const Right(unit);
    } on DatabaseException catch (e) {
      return Left(DatabaseQueryFailure('clear', e.toString()));
    } catch (e) {
      return Left(DatabaseQueryFailure('clear', e.toString()));
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
