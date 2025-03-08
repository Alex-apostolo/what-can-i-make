import 'package:cloud_firestore/cloud_firestore.dart' as firebase;
import 'package:dartz/dartz.dart';
import 'package:what_can_i_make/core/error/failures/failure.dart';
import 'package:what_can_i_make/features/user/models/user.dart';
import 'package:what_can_i_make/core/utils/firebase_error_handler.dart';
import 'package:what_can_i_make/features/user/models/user_limits.dart';

/// Repository for handling user-related Firestore operations
class UserRepository {
  final firebase.FirebaseFirestore _database;

  UserRepository({required firebase.FirebaseFirestore database})
    : _database = database;

  firebase.CollectionReference get _usersCollection =>
      _database.collection('users');

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

  /// Updates user request limit
  Future<Either<Failure, Unit>> saveRequestLimit(
    String userId,
    int requestLimit,
  ) async {
    try {
      // Use set with merge to create the document if it doesn't exist
      await _usersCollection.doc(userId).set({
        'requestsLimit': requestLimit,
      }, firebase.SetOptions(merge: true));

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

  /// Updates user request usage count
  Future<Either<Failure, Unit>> saveRequestUsage(
    String userId,
    int requestsUsed,
  ) async {
    try {
      // Use set with merge to create the document if it doesn't exist
      await _usersCollection.doc(userId).set({
        'requestsUsed': requestsUsed,
      }, firebase.SetOptions(merge: true));

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
      await _usersCollection.doc(userId).update({
        'requestsUsed': UserLimits.initialRequestCount,
      });
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
      final userData = docSnapshot.data() as Map<String, dynamic>;
      return Right(userData['requestsUsed']);
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

  /// Gets the current request limit for a user
  Future<Either<Failure, int>> getRequestLimit(String userId) async {
    try {
      final docSnapshot = await _usersCollection.doc(userId).get();
      final userData = docSnapshot.data() as Map<String, dynamic>;
      return Right(userData['requestsLimit']);
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
