import 'dart:async';
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:what_can_i_make/core/error/failures/failure.dart';
import 'package:what_can_i_make/features/user/data/user_repository.dart';
import 'package:what_can_i_make/features/user/domain/request_limit_service.dart';
import 'package:what_can_i_make/features/payment/models/payment_package.dart';
import 'package:logger/logger.dart';

/// Service to handle payment operations for API request packages using in-app purchases
class PaymentService extends ChangeNotifier {
  // Dependencies
  final FirebaseAuth _auth;
  final UserRepository _userRepository;
  final RequestLimitService _requestLimitService;
  final Logger _logger = Logger();

  // In-app purchase related fields
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  List<ProductDetails>? _products;
  bool _isAvailable = false;
  bool _purchasePending = false;
  String? _purchaseError;

  // Completer to handle async purchase completion
  Completer<Either<Failure, Unit>>? _currentPurchaseCompleter;

  // Product IDs for in-app purchases
  static const Set<String> _productIds = {
    'api_requests_basic',
    'api_requests_standard',
    'api_requests_premium',
  };

  // Package definitions
  static final Map<String, PaymentPackage> _packageDefinitions = {
    'api_requests_basic': PaymentPackage(
      id: 'api_requests_basic',
      name: 'Basic',
      requestCount: 250,
      price: 2.99,
      description: '250 additional API requests',
    ),
    'api_requests_standard': PaymentPackage(
      id: 'api_requests_standard',
      name: 'Standard',
      requestCount: 500,
      price: 4.99,
      description: '500 additional API requests',
      isBestValue: true,
    ),
    'api_requests_premium': PaymentPackage(
      id: 'api_requests_premium',
      name: 'Premium',
      requestCount: 1500,
      price: 9.99,
      description: '1500 additional API requests',
    ),
  };

  // Public getters
  bool get isAvailable => _isAvailable;
  bool get purchasePending => _purchasePending;
  String? get purchaseError => _purchaseError;
  List<ProductDetails>? get products => _products;

  PaymentService({
    required FirebaseAuth auth,
    required UserRepository userRepository,
    required RequestLimitService requestLimitService,
  }) : _auth = auth,
       _userRepository = userRepository,
       _requestLimitService = requestLimitService {
    _initInAppPurchases();
  }

  /// Initialize in-app purchases
  Future<void> _initInAppPurchases() async {
    // For web, use simulated purchase flow
    if (kIsWeb) {
      _isAvailable = true;
      notifyListeners();
      return;
    }

    // Check if the store is available
    _isAvailable = await _inAppPurchase.isAvailable();

    if (!_isAvailable) {
      _logger.w('In-app purchases not available');
      notifyListeners();
      return;
    }

    // Listen for purchase updates
    _subscription = _inAppPurchase.purchaseStream.listen(
      _listenToPurchaseUpdated,
      onDone: () => _subscription.cancel(),
      onError: (error) => _logger.e('Error in purchase stream', error: error),
    );

    // Load products
    await _loadProducts();
    notifyListeners();
  }

  /// Load available products from the store
  Future<void> _loadProducts() async {
    try {
      final response = await _inAppPurchase.queryProductDetails(_productIds);

      if (response.notFoundIDs.isNotEmpty) {
        _logger.w('Products not found: ${response.notFoundIDs}');
      }

      _products = response.productDetails;
      _logger.i('Loaded ${_products?.length} products');
    } catch (e) {
      _logger.e('Error loading products', error: e);
    }
  }

  /// Get a package definition by product ID
  PaymentPackage _getPackageDefinition(String productId) {
    return _packageDefinitions[productId] ??
        (throw Exception('Unknown product ID: $productId'));
  }

  /// Get available payment packages
  List<PaymentPackage> getAvailablePackages() {
    // If products aren't loaded yet, return default packages
    if (kIsWeb || _products == null || _products!.isEmpty) {
      return _packageDefinitions.values.toList();
    }

    // Map product details to payment packages with store prices
    return _products!.map((product) {
      final package = _getPackageDefinition(product.id);
      return PaymentPackage(
        id: package.id,
        name: package.name,
        requestCount: package.requestCount,
        price: double.tryParse(product.price) ?? package.price,
        description: package.description,
        isBestValue: package.isBestValue,
      );
    }).toList();
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

      // For web or debug mode, simulate a successful purchase
      if (kIsWeb || kDebugMode) {
        return _simulatePurchase(package);
      }

      // Find the product details for this package
      final productDetails = _products?.firstWhere(
        (product) => product.id == package.id,
        orElse: () => throw Exception('Product not found: ${package.id}'),
      );

      if (productDetails == null) {
        return Left(PaymentFailure('Product not available', null));
      }

      // Create a completer to handle the async purchase
      _currentPurchaseCompleter = Completer<Either<Failure, Unit>>();

      // Start the purchase
      _purchasePending = true;
      _purchaseError = null;
      notifyListeners();

      // Make the purchase
      await _inAppPurchase.buyConsumable(
        purchaseParam: PurchaseParam(
          productDetails: productDetails,
          applicationUserName: userId,
        ),
        autoConsume: Platform.isIOS,
      );

      // Wait for the purchase to complete
      return _currentPurchaseCompleter!.future;
    } on Exception catch (e) {
      _purchasePending = false;
      _purchaseError = e.toString();
      notifyListeners();
      return Left(PaymentFailure('Payment processing failed', e));
    }
  }

  /// Simulate a purchase for web or debug mode
  Future<Either<Failure, Unit>> _simulatePurchase(
    PaymentPackage package,
  ) async {
    _purchasePending = true;
    notifyListeners();

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    _purchasePending = false;
    notifyListeners();

    // Update the user's request limit
    return _updateUserRequestLimit(
      _auth.currentUser!.uid,
      package.requestCount,
    );
  }

  /// Update the user's request limit
  Future<Either<Failure, Unit>> _updateUserRequestLimit(
    String userId,
    int additionalRequests,
  ) async {
    final currentLimit = _requestLimitService.requestsLimit;
    final newLimit = currentLimit + additionalRequests;

    final result = await _userRepository.saveRequestLimit(userId, newLimit);

    return result.fold((failure) => Left(failure), (_) async {
      await _requestLimitService.refreshLimits();
      return const Right(unit);
    });
  }

  /// Handle purchase updates from the store
  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        _purchasePending = true;
      } else {
        _purchasePending = false;

        // Handle different purchase statuses
        switch (purchaseDetails.status) {
          case PurchaseStatus.error:
            _handleError(purchaseDetails.error!);
            break;
          case PurchaseStatus.purchased:
          case PurchaseStatus.restored:
            _deliverProduct(purchaseDetails);
            break;
          case PurchaseStatus.canceled:
            _handleCanceled();
            break;
          default:
            break;
        }

        // Complete the purchase on iOS
        if (Platform.isIOS) {
          _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    }
    notifyListeners();
  }

  /// Handle purchase errors
  void _handleError(IAPError error) {
    _purchaseError = error.message;
    _logger.e('Purchase error: ${error.message}', error: error);

    _completeWithFailure(error.message);
  }

  /// Handle canceled purchases
  void _handleCanceled() {
    _logger.i('Purchase canceled by user');
    _completeWithFailure('Purchase canceled');
  }

  /// Complete the purchase with a failure
  void _completeWithFailure(String message) {
    if (_currentPurchaseCompleter != null &&
        !_currentPurchaseCompleter!.isCompleted) {
      _currentPurchaseCompleter!.complete(
        Left(PaymentFailure(message, Exception(message))),
      );
    }
  }

  /// Deliver the purchased product to the user
  Future<void> _deliverProduct(PurchaseDetails purchaseDetails) async {
    try {
      // Get the package for this product
      final package = _getPackageDefinition(purchaseDetails.productID);
      final userId = _auth.currentUser!.uid;

      // Update the user's request limit
      final result = await _updateUserRequestLimit(
        userId,
        package.requestCount,
      );

      // Complete the purchase
      if (_currentPurchaseCompleter != null &&
          !_currentPurchaseCompleter!.isCompleted) {
        _currentPurchaseCompleter!.complete(result);
      }

      // TODO: Mark the purchase as consumed on Android
      // if (Platform.isAndroid) {
      //   final consumable = GooglePlayConsumableDetails.fromPurchaseDetails(purchaseDetails);
      //   await _inAppPurchase.completePurchase(consumable);
      // }
    } catch (e) {
      _logger.e('Error delivering product', error: e);

      if (_currentPurchaseCompleter != null &&
          !_currentPurchaseCompleter!.isCompleted) {
        _currentPurchaseCompleter!.complete(
          Left(PaymentFailure('Failed to deliver product', Exception(e))),
        );
      }
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Custom failure for payment operations
class PaymentFailure extends Failure {
  const PaymentFailure(super.message, super.error);
}
