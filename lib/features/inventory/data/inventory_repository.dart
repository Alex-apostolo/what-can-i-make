import 'package:cloud_firestore/cloud_firestore.dart' as firebase;
import 'package:dartz/dartz.dart';
import 'package:what_can_i_make/core/error/failures/failure.dart';
import 'package:what_can_i_make/features/inventory/models/ingredient.dart';
import 'package:what_can_i_make/core/utils/firebase_error_handler.dart';

/// Repository for handling inventory-related Firestore operations.
class InventoryRepository {
  final firebase.FirebaseFirestore _database;

  InventoryRepository({required firebase.FirebaseFirestore database})
    : _database = database;

  firebase.CollectionReference get _ingredientsCollection =>
      _database.collection('ingredients');

  /// Retrieves all inventory items, optionally sorted by timestamp.
  Future<Either<Failure, List<Ingredient>>> getInventory({
    bool sortByTimestamp = true,
  }) async {
    try {
      final snapshot =
          await _ingredientsCollection
              .orderBy('createdAt', descending: true)
              .get();
      final ingredients =
          snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Ingredient.fromJson({
              ...data,
              'id': doc.id,
              'createdAt': data['createdAt'].toDate(),
            });
          }).toList();

      return Right(ingredients);
    } on firebase.FirebaseException catch (e) {
      return Left(
        DatabaseQueryFailure(
          FirebaseErrorHandler.getFriendlyErrorMessage(e),
          e,
        ),
      );
    } on Exception catch (e) {
      return Left(GenericFailure(error: e));
    }
  }

  /// Adds multiple ingredients using batch writes.
  Future<Either<Failure, Unit>> addIngredients(
    List<IngredientInput> ingredientInputs,
  ) async {
    try {
      final batch = _database.batch();

      for (final ingredientInput in ingredientInputs) {
        final docRef = _ingredientsCollection.doc();

        final ingredientData = ingredientInput.toJson();
        ingredientData['createdAt'] = firebase.FieldValue.serverTimestamp();
        ingredientData['id'] = docRef.id;

        batch.set(docRef, ingredientData);
      }

      await batch.commit();
      return Right(unit);
    } on firebase.FirebaseException catch (e) {
      return Left(
        DatabaseQueryFailure(
          FirebaseErrorHandler.getFriendlyErrorMessage(e),
          e,
        ),
      );
    } on Exception catch (e) {
      return Left(GenericFailure(error: e));
    }
  }

  /// Updates an existing ingredient.
  Future<Either<Failure, Unit>> updateIngredient(Ingredient ingredient) async {
    try {
      await _ingredientsCollection
          .doc(ingredient.id)
          .update(
            ingredient.toJson()
              ..remove('id')
              ..remove('createdAt'),
          );
      return Right(unit);
    } on firebase.FirebaseException catch (e) {
      return Left(
        DatabaseQueryFailure(
          FirebaseErrorHandler.getFriendlyErrorMessage(e),
          e,
        ),
      );
    } on Exception catch (e) {
      return Left(GenericFailure(error: e));
    }
  }

  /// Removes an ingredient.
  Future<Either<Failure, Unit>> removeIngredient(Ingredient ingredient) async {
    try {
      await _ingredientsCollection.doc(ingredient.id).delete();
      return Right(unit);
    } on firebase.FirebaseException catch (e) {
      return Left(
        DatabaseQueryFailure(
          FirebaseErrorHandler.getFriendlyErrorMessage(e),
          e,
        ),
      );
    } on Exception catch (e) {
      return Left(GenericFailure(error: e));
    }
  }

  /// Clears all inventory items using batch delete.
  Future<Either<Failure, Unit>> clearInventory() async {
    try {
      final snapshot = await _ingredientsCollection.get();
      final batch = _database.batch();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      return Right(unit);
    } on firebase.FirebaseException catch (e) {
      return Left(
        DatabaseQueryFailure(
          FirebaseErrorHandler.getFriendlyErrorMessage(e),
          e,
        ),
      );
    } on Exception catch (e) {
      return Left(GenericFailure(error: e));
    }
  }
}
