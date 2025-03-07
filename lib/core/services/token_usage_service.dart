import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:what_can_i_make/core/error/failures/failure.dart';
import 'package:dartz/dartz.dart';

/// Service to track and manage token usage for OpenAI API calls
class TokenUsageService extends ChangeNotifier {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final Logger _logger = Logger();

  // In-memory cache of token usage
  int _tokensUsed = 0;
  final int _tokensLimit = 100; // Default limit

  TokenUsageService({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) : _firestore = firestore,
       _auth = auth {
    // Load token usage when service is created
    _loadTokenUsage();
  }

  /// Get the current number of tokens used
  int get tokensUsed => _tokensUsed;

  /// Get the token limit for the current user
  int get tokensLimit => _tokensLimit;

  /// Check if the user has exceeded their token limit
  bool get hasExceededLimit => _tokensUsed >= _tokensLimit;

  /// Record token usage from an API call
  Future<Either<Failure, void>> recordTokenUsage(int tokens) async {
    try {
      // Update in-memory counter first
      _tokensUsed += tokens;
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
          transaction.update(userRef, {'tokensUsed': _tokensUsed});
        } else {
          transaction.set(userRef, {'tokensUsed': _tokensUsed});
        }
      });

      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(DatabaseQueryFailure('Failed to update token usage', e));
    } on Exception catch (e) {
      return Left(GenericFailure(e));
    }
  }

  /// Reset token usage for the current user
  Future<Either<Failure, void>> resetTokenUsage() async {
    try {
      _tokensUsed = 0;
      notifyListeners();

      final userId = _auth.currentUser?.uid;

      if (userId != null) {
        await _firestore.collection('users').doc(userId).update({
          'tokensUsed': 0,
        });
      }

      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(DatabaseQueryFailure('Failed to reset token usage', e));
    } on Exception catch (e) {
      return Left(GenericFailure(e));
    }
  }

  /// Load token usage from Firestore
  Future<void> _loadTokenUsage() async {
    try {
      final userId = _auth.currentUser?.uid;

      if (userId != null) {
        final userDoc = await _firestore.collection('users').doc(userId).get();

        if (userDoc.exists) {
          _tokensUsed = userDoc.data()?['tokensUsed'] as int? ?? 0;
          notifyListeners();
        }
      }
    } catch (e) {
      // Just log the error, don't throw
      _logger.e('Error loading token usage', error: e);
    }
  }
}
