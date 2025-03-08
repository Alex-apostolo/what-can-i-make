import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:what_can_i_make/core/error/failures/failure.dart';
import 'package:what_can_i_make/features/user/data/user_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:what_can_i_make/features/user/models/user_limits.dart';

/// Service to track and manage API request limits
class RequestLimitService extends ChangeNotifier {
  final UserRepository _userRepository;
  final FirebaseAuth _auth;
  final Logger _logger = Logger();

  // In-memory cache of requests used and limit
  int _requestsUsed = UserLimits.initialRequestCount;
  int _requestsLimit = UserLimits.defaultRequestLimit; // Default limit

  RequestLimitService({
    required UserRepository userRepository,
    required FirebaseAuth auth,
  }) : _userRepository = userRepository,
       _auth = auth {
    // Load request usage when service is created
    _loadUserData();
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
      return _userRepository.saveRequestUsage(userId, _requestsUsed);
    } on Exception catch (e) {
      return Left(GenericFailure(error: e));
    }
  }

  /// Reset request usage for the current user
  Future<Either<Failure, Unit>> resetRequestUsage() async {
    try {
      _requestsUsed = UserLimits.initialRequestCount;
      notifyListeners();

      final userId = _auth.currentUser?.uid;

      if (userId != null) {
        return _userRepository.resetRequestUsage(userId);
      }

      return const Right(unit);
    } on Exception catch (e) {
      return Left(GenericFailure(error: e));
    }
  }

  /// Load both request usage and limit from repository
  Future<void> _loadUserData() async {
    try {
      final userId = _auth.currentUser?.uid;

      if (userId != null) {
        // Load request usage
        final usageResult = await _userRepository.getRequestUsage(userId);
        usageResult.fold(
          (failure) =>
              _logger.e('Error loading request usage', error: failure.error),
          (usage) {
            _requestsUsed = usage;
            notifyListeners();
          },
        );

        // Load request limit
        final limitResult = await _userRepository.getRequestLimit(userId);
        limitResult.fold(
          (failure) =>
              _logger.e('Error loading request limit', error: failure.error),
          (limit) {
            _requestsLimit = limit;
            notifyListeners();
          },
        );
      }
    } catch (e) {
      // Just log the error, don't throw
      _logger.e('Error loading user data', error: e);
    }
  }
}
