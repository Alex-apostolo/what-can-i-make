import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:what_can_i_make/core/error/failures/failure.dart';
import 'package:what_can_i_make/features/user/data/user_repository.dart';
import 'package:dartz/dartz.dart';

/// Service to track and manage API request limits
class RequestLimitService extends ChangeNotifier {
  final UserRepository _userRepository;
  final FirebaseAuth _auth;
  final Logger _logger = Logger();

  // In-memory cache of requests used
  int _requestsUsed = 0;
  final int _requestsLimit = 50; // Default limit

  RequestLimitService({
    required UserRepository userRepository,
    required FirebaseAuth auth,
  }) : _userRepository = userRepository,
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
  Future<Either<Failure, Unit>> recordRequest() async {
    try {
      // Update in-memory counter first
      _requestsUsed += 1;
      notifyListeners();

      final userId = _auth.currentUser?.uid;

      // If no user is logged in, only keep the in-memory counter
      if (userId == null) {
        return const Right(unit);
      }

      // Update user's request usage in repository
      return _userRepository.updateRequestUsage(userId, _requestsUsed);
    } on Exception catch (e) {
      return Left(GenericFailure(e));
    }
  }

  /// Reset request usage for the current user
  Future<Either<Failure, Unit>> resetRequestUsage() async {
    try {
      _requestsUsed = 0;
      notifyListeners();

      final userId = _auth.currentUser?.uid;

      if (userId != null) {
        return _userRepository.resetRequestUsage(userId);
      }

      return const Right(unit);
    } on Exception catch (e) {
      return Left(GenericFailure(e));
    }
  }

  /// Load request usage from repository
  Future<void> _loadRequestUsage() async {
    try {
      final userId = _auth.currentUser?.uid;

      if (userId != null) {
        final result = await _userRepository.getRequestUsage(userId);

        result.fold(
          (failure) =>
              _logger.e('Error loading request usage', error: failure.error),
          (usage) {
            _requestsUsed = usage;
            notifyListeners();
          },
        );
      }
    } catch (e) {
      // Just log the error, don't throw
      _logger.e('Error loading request usage', error: e);
    }
  }
}
