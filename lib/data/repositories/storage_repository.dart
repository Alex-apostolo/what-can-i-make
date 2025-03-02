import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:dartz/dartz.dart';
import '../../core/error/failures/failure.dart';
import '../../domain/models/ingredient.dart';

/// Repository for handling persistent storage of ingredients
class StorageRepository {
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
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE ingredients(
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            quantity INTEGER NOT NULL,
            brand TEXT,
            unit TEXT NOT NULL
          )
        ''');
      },
    );
  }

  /// Factory constructor to initialize the database
  static Future<StorageRepository> initialize() async {
    final repository = StorageRepository();
    await repository.database;
    return repository;
  }

  /// Retrieves all ingredients from the inventory
  Future<Either<Failure, List<Ingredient>>> getInventory() async {
    try {
      final db = await database;
      final items = await db.query('ingredients');

      return Right(items.map((item) => Ingredient.fromJson(item)).toList());
    } on DatabaseException catch (e) {
      return Left(DatabaseQueryFailure('query', e.toString()));
    } catch (e) {
      return Left(DatabaseQueryFailure('query', e.toString()));
    }
  }

  /// Adds a new ingredient to the inventory
  Future<Either<Failure, Unit>> addItem(Ingredient item) async {
    try {
      final db = await database;
      await db.insert('ingredients', item.toJson());

      return const Right(unit);
    } on DatabaseException catch (e) {
      return Left(DatabaseQueryFailure('insert', e.toString()));
    } catch (e) {
      return Left(DatabaseQueryFailure('insert', e.toString()));
    }
  }

  /// Adds multiple ingredients to the inventory
  Future<Either<Failure, Unit>> addItems(List<Ingredient> items) async {
    try {
      final db = await database;
      final batch = db.batch();

      for (final item in items) {
        batch.insert('ingredients', item.toJson());
      }

      await batch.commit(noResult: true);
      return const Right(unit);
    } on DatabaseException catch (e) {
      return Left(DatabaseQueryFailure('batch insert', e.toString()));
    } catch (e) {
      return Left(DatabaseQueryFailure('batch insert', e.toString()));
    }
  }

  /// Updates an existing ingredient in the inventory
  Future<Either<Failure, Unit>> updateItem(Ingredient item) async {
    try {
      final db = await database;
      final count = await db.update(
        'ingredients',
        item.toJson(),
        where: 'id = ?',
        whereArgs: [item.id],
      );

      if (count == 0) {
        return Left(ItemNotFoundFailure(item.id));
      }

      return const Right(unit);
    } on DatabaseException catch (e) {
      return Left(DatabaseQueryFailure('update', e.toString()));
    } catch (e) {
      return Left(DatabaseQueryFailure('update', e.toString()));
    }
  }

  /// Removes an ingredient from the inventory
  Future<Either<Failure, Unit>> removeItem(Ingredient item) async {
    try {
      final db = await database;
      final count = await db.delete(
        'ingredients',
        where: 'id = ?',
        whereArgs: [item.id],
      );

      if (count == 0) {
        return Left(ItemNotFoundFailure(item.id));
      }

      return const Right(unit);
    } on DatabaseException catch (e) {
      return Left(DatabaseQueryFailure('delete', e.toString()));
    } catch (e) {
      return Left(DatabaseQueryFailure('delete', e.toString()));
    }
  }

  /// Clears all inventory ingredients
  Future<Either<Failure, Unit>> clearInventory() async {
    try {
      final db = await database;
      await db.delete('ingredients');
      return const Right(unit);
    } on DatabaseException catch (e) {
      return Left(DatabaseQueryFailure('clear', e.toString()));
    } catch (e) {
      return Left(DatabaseQueryFailure('clear', e.toString()));
    }
  }

  /// Closes the database connection
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
