import 'package:cloud_firestore/cloud_firestore.dart' as firebase;
import 'package:dartz/dartz.dart';
import 'package:what_can_i_make/core/error/failures/failure.dart';
import 'package:what_can_i_make/core/models/ingredient.dart';
import 'package:what_can_i_make/core/database/database.dart';

/// Repository for handling Firestore storage operations.
class StorageRepository {
  final AppDatabase database;

  StorageRepository({required this.database});

  firebase.CollectionReference get _ingredientsCollection =>
      database.collection('ingredients');

  /// Retrieves all ingredients, optionally sorted by timestamp.
  Future<Either<Failure, List<Ingredient>>> getIngredients({
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
      return Left(DatabaseQueryFailure(_getFriendlyErrorMessage(e), e));
    } on Exception catch (e) {
      return Left(GenericFailure(e));
    }
  }

  /// Adds multiple ingredients using batch writes.
  Future<Either<Failure, Unit>> addIngredients(
    List<IngredientInput> ingredientInputs,
  ) async {
    try {
      final batch = database.batch();

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
      return Left(DatabaseQueryFailure(_getFriendlyErrorMessage(e), e));
    } on Exception catch (e) {
      return Left(GenericFailure(e));
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
      return Left(DatabaseQueryFailure(_getFriendlyErrorMessage(e), e));
    } on Exception catch (e) {
      return Left(GenericFailure(e));
    }
  }

  /// Removes an ingredient.
  Future<Either<Failure, Unit>> removeIngredient(Ingredient ingredient) async {
    try {
      await _ingredientsCollection.doc(ingredient.id).delete();
      return Right(unit);
    } on firebase.FirebaseException catch (e) {
      return Left(DatabaseQueryFailure(_getFriendlyErrorMessage(e), e));
    } on Exception catch (e) {
      return Left(GenericFailure(e));
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
    } on firebase.FirebaseException catch (e) {
      return Left(DatabaseQueryFailure(_getFriendlyErrorMessage(e), e));
    } on Exception catch (e) {
      return Left(GenericFailure(e));
    }
  }

  String _getFriendlyErrorMessage(firebase.FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'You do not have permission to access this resource.';
      case 'unauthenticated':
        return 'You must be logged in to access this resource.';
      case 'unauthorized':
        return 'You are not authorized to access this resource.';
      case 'invalid-argument':
        return 'The request contains invalid arguments.';
      case 'resource-exhausted':
        return 'The resource has been exhausted.';
      case 'unavailable':
        return 'The service is currently unavailable.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }
}
