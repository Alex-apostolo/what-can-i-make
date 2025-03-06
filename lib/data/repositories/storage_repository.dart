import 'package:sqflite/sqflite.dart';
import 'package:dartz/dartz.dart';
import 'package:what_can_i_make/core/utils/generate_unique_id.dart';
import 'package:what_can_i_make/core/error/failures/failure.dart';
import 'package:what_can_i_make/core/models/ingredient.dart';

/// Repository for handling persistent storage
class StorageRepository {
  final Database database;

  StorageRepository({required this.database});

  /// Retrieves all ingredients
  Future<Either<Failure, List<Ingredient>>> getIngredients({
    bool sortByTimestamp = true,
  }) async {
    try {
      final db = database;

      final ingredients = await db.query('ingredients');

      final ingredientsJson =
          ingredients
              .map((ingredient) => Ingredient.fromJson(ingredient))
              .toList();

      if (sortByTimestamp) {
        ingredientsJson.sort(
          (a, b) =>
              getTimestampFromId(b.id).compareTo(getTimestampFromId(a.id)),
        );
      }

      return Right(ingredientsJson);
    } on DatabaseException {
      return Left(DatabaseQueryFailure('query'));
    }
  }

  /// Adds a new ingredient
  Future<Either<Failure, Unit>> addIngredient(Ingredient ingredient) async {
    try {
      final db = database;
      await db.insert('ingredients', ingredient.toJson());

      return Right(unit);
    } on DatabaseException {
      return Left(DatabaseQueryFailure('insert'));
    }
  }

  /// Adds multiple ingredients
  Future<Either<Failure, Unit>> addIngredients(
    List<Ingredient> ingredients,
  ) async {
    try {
      final db = database;
      final batch = db.batch();

      for (final item in ingredients) {
        batch.insert('ingredients', item.toJson());
      }

      await batch.commit(noResult: true);
      return Right(unit);
    } on DatabaseException {
      return Left(DatabaseQueryFailure('batch insert'));
    }
  }

  /// Updates an existing ingredient
  Future<Either<Failure, Unit>> updateIngredient(Ingredient ingredient) async {
    try {
      final db = database;
      final count = await db.update(
        'ingredients',
        ingredient.toJson(),
        where: 'id = ?',
        whereArgs: [ingredient.id],
      );

      if (count == 0) {
        return Left(ItemNotFoundFailure(ingredient.id));
      }

      return Right(unit);
    } on DatabaseException {
      return Left(DatabaseQueryFailure('update'));
    }
  }

  /// Removes an ingredient
  Future<Either<Failure, Unit>> removeIngredient(Ingredient ingredient) async {
    try {
      final db = database;
      final count = await db.delete(
        'ingredients',
        where: 'id = ?',
        whereArgs: [ingredient.id],
      );

      if (count == 0) {
        return Left(ItemNotFoundFailure(ingredient.id));
      }

      return Right(unit);
    } on DatabaseException {
      return Left(DatabaseQueryFailure('delete'));
    }
  }

  /// Clears all ingredients
  Future<Either<Failure, Unit>> clearIngredients() async {
    try {
      final db = database;
      await db.delete('ingredients');
      return Right(unit);
    } on DatabaseException {
      return Left(DatabaseQueryFailure('clear'));
    }
  }

  /// Closes the database connection
  Future<void> close() async {
    final db = database;
    await db.close();
  }
}
