import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:what_can_i_make/core/error/failures/failure.dart';
import 'package:what_can_i_make/core/models/ingredient.dart';
import 'package:what_can_i_make/core/database/database.dart';
import 'package:what_can_i_make/core/utils/id.dart';

/// Repository for handling Firestore storage operations.
class StorageRepository {
  final AppDatabase database;

  StorageRepository({required this.database});

  CollectionReference get _ingredientsCollection =>
      database.collection('ingredients');

  /// Retrieves all ingredients, optionally sorted by timestamp.
  Future<Either<Failure, List<Ingredient>>> getIngredients({
    bool sortByTimestamp = true,
  }) async {
    try {
      final snapshot = await _ingredientsCollection.get();
      final ingredients =
          snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Ingredient.fromJson({...data, 'id': doc.id});
          }).toList();

      if (sortByTimestamp) {
        ingredients.sort(
          (a, b) =>
              (getTimestampFromId(b.id)).compareTo(getTimestampFromId(a.id)),
        );
      }

      return Right(ingredients);
    } on FirebaseException catch (e) {
      return Left(DatabaseQueryFailure('Query failed: ${e.message}'));
    }
  }

  /// Adds multiple ingredients using batch writes.
  Future<Either<Failure, Unit>> addIngredients(
    List<Ingredient> ingredients,
  ) async {
    try {
      final batch = database.batch();

      for (final ingredient in ingredients) {
        final docRef = _ingredientsCollection.doc();

        final ingredientData = ingredient.copyWith(id: docRef.id).toJson();
        ingredientData['timestamp'] = FieldValue.serverTimestamp();

        batch.set(docRef, ingredientData);
      }

      await batch.commit();
      return Right(unit);
    } on FirebaseException catch (e) {
      return Left(DatabaseQueryFailure('Batch insert failed: ${e.message}'));
    }
  }

  /// Updates an existing ingredient.
  Future<Either<Failure, Unit>> updateIngredient(Ingredient ingredient) async {
    try {
      await _ingredientsCollection
          .doc(ingredient.id)
          .update(ingredient.toJson()..remove('id'));
      return Right(unit);
    } on FirebaseException catch (e) {
      return Left(DatabaseQueryFailure('Update failed: ${e.message}'));
    }
  }

  /// Removes an ingredient.
  Future<Either<Failure, Unit>> removeIngredient(Ingredient ingredient) async {
    try {
      await _ingredientsCollection.doc(ingredient.id).delete();
      return Right(unit);
    } on FirebaseException catch (e) {
      return Left(DatabaseQueryFailure('Delete failed: ${e.message}'));
    }
  }

  /// Clears all ingredients using batch delete.
  Future<Either<Failure, Unit>> clearIngredients() async {
    try {
      final snapshot = await _ingredientsCollection.get();
      final batch = database.batch();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      return Right(unit);
    } on FirebaseException catch (e) {
      return Left(DatabaseQueryFailure('Clear failed: ${e.message}'));
    }
  }
}
