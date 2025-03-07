import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:what_can_i_make/core/error/failures/failure.dart';
import 'package:dartz/dartz.dart';

/// Service to track and manage API request limits
class RequestLimitService extends ChangeNotifier {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final Logger _logger = Logger();

  // In-memory cache of requests used
  int _requestsUsed = 0;
  final int _requestsLimit = 50; // Default limit

  RequestLimitService({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) : _firestore = firestore,
       _auth = auth {
    // Load request usage when service is created
    _loadRequestUsage();
  }

  /// Get the current number of requests used
  int get requestsUsed => _requestsUsed;

  /// Get the request limit for the current user
  int get requestsLimit => _requestsLimit;

  /// Check if the user has exceeded their request limit
  bool get hasExceededLimit => _requestsUsed >= _requestsLimit;

  /// Record a new API request
  Future<Either<Failure, void>> recordRequest() async {
    try {
      // Update in-memory counter first
      _requestsUsed += 1;
      notifyListeners();

      final userId = _auth.currentUser?.uid;

      // If no user is logged in, only keep the in-memory counter
      if (userId == null) {
        return const Right(null);
      }

      // Update Firestore document
      final userRef = _firestore.collection('users').doc(userId);

      await _firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);

        if (userDoc.exists) {
          transaction.update(userRef, {'requestsUsed': _requestsUsed});
        } else {
          transaction.set(userRef, {'requestsUsed': _requestsUsed});
        }
      });

      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(DatabaseQueryFailure('Failed to update request usage', e));
    } on Exception catch (e) {
      return Left(GenericFailure(e));
    }
  }

  /// Reset request usage for the current user
  Future<Either<Failure, void>> resetRequestUsage() async {
    try {
      _requestsUsed = 0;
      notifyListeners();

      final userId = _auth.currentUser?.uid;

      if (userId != null) {
        await _firestore.collection('users').doc(userId).update({
          'requestsUsed': 0,
        });
      }

      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(DatabaseQueryFailure('Failed to reset request usage', e));
    } on Exception catch (e) {
      return Left(GenericFailure(e));
    }
  }

  /// Load request usage from Firestore
  Future<void> _loadRequestUsage() async {
    try {
      final userId = _auth.currentUser?.uid;

      if (userId != null) {
        final userDoc = await _firestore.collection('users').doc(userId).get();

        if (userDoc.exists) {
          _requestsUsed = userDoc.data()?['requestsUsed'] as int? ?? 0;
          notifyListeners();
        }
      }
    } catch (e) {
      // Just log the error, don't throw
      _logger.e('Error loading request usage', error: e);
    }
  }
}
