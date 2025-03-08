import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:what_can_i_make/core/error/error_handler.dart';
import 'package:what_can_i_make/core/utils/logger.dart';
import 'package:what_can_i_make/features/inventory/domain/inventory_service.dart';
import 'package:what_can_i_make/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:what_can_i_make/features/user/domain/request_limit_service.dart';
import 'package:what_can_i_make/features/user/data/user_repository.dart';
import 'package:what_can_i_make/features/inventory/data/inventory_repository.dart';
import 'package:what_can_i_make/features/auth/domain/auth_service.dart';
import 'package:what_can_i_make/features/payment/domain/payment_service.dart';

import 'app_services.dart';

class AppInitializer {
  final GlobalKey<NavigatorState> navigatorKey;
  final AppLogger logger;

  AppInitializer({required this.navigatorKey, required this.logger});

  Future<AppServices> initialize() async {
    // Set up error handling first
    _setupErrorHandling();

    // Initialize Flutter binding
    WidgetsFlutterBinding.ensureInitialized();

    logger.i('Application starting');

    try {
      // Load environment variables
      await _loadEnvironmentVariables();

      // Initialize Firebase and Crashlytics
      await _initializeFirebase();

      // Set up services and repositories
      final database = FirebaseFirestore.instance;
      final userRepository = UserRepository(database: database);
      final inventoryRepository = InventoryRepository(database: database);
      final inventoryService = InventoryService(
        inventoryRepository: inventoryRepository,
      );
      final requestLimitService = RequestLimitService(
        userRepository: userRepository,
        auth: FirebaseAuth.instance,
      );
      final authService = AuthService(
        userRepository: userRepository,
        errorHandler: ErrorHandler(navigatorKey: navigatorKey),
      );
      final paymentService = PaymentService(
        auth: FirebaseAuth.instance,
        userRepository: userRepository,
        requestLimitService: requestLimitService,
      );

      // Set device orientation
      await _setDeviceOrientation();

      logger.i('Application initialization complete');
      return AppServices(
        errorHandler: ErrorHandler(navigatorKey: navigatorKey),
        inventoryRepository: inventoryRepository,
        userRepository: userRepository,
        inventoryService: inventoryService,
        requestLimitService: requestLimitService,
        authService: authService,
        paymentService: paymentService,
      );
    } catch (e, stackTrace) {
      logger.f(
        'Failed to initialize application',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  void _setupErrorHandling() {
    // Catch Flutter errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      logger.e(
        'Flutter error caught by main.dart',
        error: details.exception,
        stackTrace: details.stack,
      );
    };

    // Catch async errors that aren't caught by the Flutter framework
    PlatformDispatcher.instance.onError = (error, stack) {
      logger.e('Uncaught platform error', error: error, stackTrace: stack);
      return true;
    };
  }

  Future<void> _loadEnvironmentVariables() async {
    await dotenv.load();
    logger.d('Environment variables loaded');
  }

  Future<void> _initializeFirebase() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    logger.d('Firebase initialized');

    // Initialize Crashlytics
    await _initializeCrashlytics();
    logger.d('Crashlytics initialized');
  }

  Future<void> _setDeviceOrientation() async {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  Future<void> _initializeCrashlytics() async {
    // Pass all uncaught errors from the framework to Crashlytics
    final crashlytics = FirebaseCrashlytics.instance;

    // Enable Crashlytics collection even in debug mode for testing
    // Note: In production, you might want to set this back to !kDebugMode
    await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);

    // Add custom keys for additional context
    await crashlytics.setCustomKey('app_version', '1.0.0');
    await crashlytics.setCustomKey(
      'build_type',
      kDebugMode ? 'debug' : 'release',
    );

    // Log a message to indicate Crashlytics is initialized
    await crashlytics.log('Crashlytics initialized');
  }
}
