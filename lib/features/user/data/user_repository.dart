import 'package:cloud_firestore/cloud_firestore.dart' as firebase;
import 'package:dartz/dartz.dart';
import 'package:what_can_i_make/core/error/failures/failure.dart';
import 'package:what_can_i_make/features/user/models/user.dart';
import 'package:what_can_i_make/core/utils/firebase_error_handler.dart';

/// Repository for handling user-related Firestore operations
class UserRepository {
  final firebase.FirebaseFirestore _database;

  UserRepository({required firebase.FirebaseFirestore database})
    : _database = database;

  firebase.CollectionReference get _usersCollection =>
      _database.collection('users');

  /// Creates or updates a user document in Firestore
  Future<Either<Failure, Unit>> saveUser(User user) async {
    try {
      await _usersCollection.doc(user.id).set(user.toJson());
      return const Right(unit);
    } on firebase.FirebaseException catch (e) {
      return Left(
        DatabaseQueryFailure(
          FirebaseErrorHandler.getFriendlyErrorMessage(e),
          e,
        ),
      );
    } on Exception catch (e) {
      return Left(GenericFailure(e));
    }
  }

  /// Retrieves a user by ID
  Future<Either<Failure, User>> getUserById(String userId) async {
    try {
      final docSnapshot = await _usersCollection.doc(userId).get();

      if (!docSnapshot.exists) {
        return Left(
          ItemNotFoundFailure(
            'User with ID $userId not found',
            Exception('Document does not exist'),
          ),
        );
      }

      final userData = docSnapshot.data() as Map<String, dynamic>;
      return Right(User.fromJson(userData));
    } on firebase.FirebaseException catch (e) {
      return Left(
        DatabaseQueryFailure(
          FirebaseErrorHandler.getFriendlyErrorMessage(e),
          e,
        ),
      );
    } on Exception catch (e) {
      return Left(GenericFailure(e));
    }
  }

  /// Updates user request usage count
  Future<Either<Failure, Unit>> updateRequestUsage(
    String userId,
    int requestsUsed,
  ) async {
    try {
      await _usersCollection.doc(userId).update({'requestsUsed': requestsUsed});
      return const Right(unit);
    } on firebase.FirebaseException catch (e) {
      return Left(
        DatabaseQueryFailure(
          FirebaseErrorHandler.getFriendlyErrorMessage(e),
          e,
        ),
      );
    } on Exception catch (e) {
      return Left(GenericFailure(e));
    }
  }

  /// Resets user request usage count
  Future<Either<Failure, Unit>> resetRequestUsage(String userId) async {
    try {
      await _usersCollection.doc(userId).update({'requestsUsed': 0});
      return const Right(unit);
    } on firebase.FirebaseException catch (e) {
      return Left(
        DatabaseQueryFailure(
          FirebaseErrorHandler.getFriendlyErrorMessage(e),
          e,
        ),
      );
    } on Exception catch (e) {
      return Left(GenericFailure(e));
    }
  }

  /// Gets the current request usage for a user
  Future<Either<Failure, int>> getRequestUsage(String userId) async {
    try {
      final docSnapshot = await _usersCollection.doc(userId).get();

      if (!docSnapshot.exists) {
        return const Right(
          0,
        ); // Default to 0 if user document doesn't exist yet
      }

      final userData = docSnapshot.data() as Map<String, dynamic>;
      return Right(userData['requestsUsed'] as int? ?? 0);
    } on firebase.FirebaseException catch (e) {
      return Left(
        DatabaseQueryFailure(
          FirebaseErrorHandler.getFriendlyErrorMessage(e),
          e,
        ),
      );
    } on Exception catch (e) {
      return Left(GenericFailure(e));
    }
  }
}
