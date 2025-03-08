import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:what_can_i_make/core/error/failures/failure.dart';
import 'package:what_can_i_make/features/user/data/user_repository.dart';
import 'package:what_can_i_make/features/user/domain/request_limit_service.dart';
import 'package:what_can_i_make/features/payment/models/payment_package.dart';

/// Service to handle payment operations for API request packages
class PaymentService {
  final FirebaseAuth _auth;
  final UserRepository _userRepository;
  final RequestLimitService _requestLimitService;

  PaymentService({
    required FirebaseAuth auth,
    required UserRepository userRepository,
    required RequestLimitService requestLimitService,
  }) : _auth = auth,
       _userRepository = userRepository,
       _requestLimitService = requestLimitService;

  /// Get available payment packages
  List<PaymentPackage> getAvailablePackages() {
    return [
      PaymentPackage(
        id: 'basic',
        name: 'Basic',
        requestCount: 50,
        price: 2.99,
        description: '50 additional API requests',
      ),
      PaymentPackage(
        id: 'standard',
        name: 'Standard',
        requestCount: 150,
        price: 7.99,
        description: '150 additional API requests',
        isBestValue: true,
      ),
      PaymentPackage(
        id: 'premium',
        name: 'Premium',
        requestCount: 500,
        price: 19.99,
        description: '500 additional API requests',
      ),
    ];
  }

  /// Process a payment and increase the user's request limit
  Future<Either<Failure, Unit>> purchaseRequestPackage(
    PaymentPackage package,
  ) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return Left(
          PaymentFailure('You must be logged in to make a purchase', null),
        );
      }

      // In a real app, you would integrate with a payment provider here
      // For this example, we'll simulate a successful payment

      // After successful payment, update the user's request limit
      final currentLimit = _requestLimitService.requestsLimit;
      final newLimit = currentLimit + package.requestCount;

      final result = await _userRepository.saveRequestLimit(userId, newLimit);

      // If the update was successful, refresh the request limit service
      return result.fold((failure) => Left(failure), (_) async {
        await _requestLimitService.refreshLimits();
        return const Right(unit);
      });
    } on Exception catch (e) {
      return Left(PaymentFailure('Payment processing failed', e));
    }
  }
}

/// Custom failure for payment operations
class PaymentFailure extends Failure {
  const PaymentFailure(super.message, super.error);
}
