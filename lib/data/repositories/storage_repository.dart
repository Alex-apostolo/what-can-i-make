import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../domain/models/kitchen_item.dart';
import 'package:dartz/dartz.dart';
import '../../core/error/failures/failure.dart';

/// Repository for handling persistent storage of kitchen inventory
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

  /// Factory constructor to initialize the database
  static Future<StorageRepository> initialize() async {
    final repository = StorageRepository();
    await repository.database;
    return repository;
  }

  /// Retrieves all items from the inventory
  Future<Either<Failure, List<KitchenItem>>> getInventory() async {
    try {
      final db = await database;
      final items = await db.query('items');

      return Right(
        items.map((item) => KitchenItem.fromMap(item)).toList(),
      );
    } on DatabaseException catch (e) {
      return Left(DatabaseQueryFailure('query', e.toString()));
    } catch (e) {
      return Left(DatabaseQueryFailure('query', e.toString()));
    }
  }

  /// Adds a new item to the inventory
  Future<Either<Failure, Unit>> addItem(KitchenItem item) async {
    try {
      final db = await database;
      await db.insert('items', item.toMap());

      return const Right(unit);
    } on DatabaseException catch (e) {
      return Left(DatabaseQueryFailure('insert', e.toString()));
    } catch (e) {
      return Left(DatabaseQueryFailure('insert', e.toString()));
    }
  }

  /// Adds multiple items to the inventory
  Future<Either<Failure, Unit>> addItems(List<KitchenItem> items) async {
    try {
      final db = await database;
      final batch = db.batch();

      for (final item in items) {
        batch.insert('items', item.toMap());
      }

      await batch.commit(noResult: true);
      return const Right(unit);
    } on DatabaseException catch (e) {
      return Left(DatabaseQueryFailure('batch insert', e.toString()));
    } catch (e) {
      return Left(DatabaseQueryFailure('batch insert', e.toString()));
    }
  }

  /// Updates an existing item in the inventory
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

  /// Removes an item from the inventory
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

  /// Clears all inventory items
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

  /// Closes the database connection
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
} 