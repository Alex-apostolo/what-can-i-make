import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:what_can_i_make/core/database/database.dart';
import 'package:what_can_i_make/core/utils/logger.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'data/repositories/storage_repository.dart';
import 'core/error/error_handler.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:provider/provider.dart';
import 'features/auth/domain/auth_service.dart';
import 'features/auth/presentation/auth_wrapper.dart';
import 'features/auth/presentation/sign_in_screen.dart';
import 'features/auth/presentation/sign_up_screen.dart';
import 'features/inventory/domain/inventory_service.dart';
import 'features/inventory/presentation/inventory_screen.dart';
import 'features/recipes/presentation/recipe_recommendations_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final Logger _logger = Logger('App');

void main() async {
  // Catch Flutter errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    _logger.e(
      'Flutter error caught by main.dart',
      details.exception,
      details.stack,
    );
  };

  // Catch async errors that aren't caught by the Flutter framework
  PlatformDispatcher.instance.onError = (error, stack) {
    _logger.e('Uncaught platform error', error, stack);
    return true;
  };

  WidgetsFlutterBinding.ensureInitialized();

  // Configure logger based on environment
  Logger.configure(
    minLevel: kDebugMode ? LogLevel.verbose : LogLevel.info,
    showTimestamps: true,
    showLogLevels: true,
    showTags: true,
    sendToCrashlytics: !kDebugMode, // Only send to Crashlytics in release mode
  );

  _logger.i('Application starting');

  try {
    await dotenv.load();
    _logger.d('Environment variables loaded');

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _logger.d('Firebase initialized');

    // Initialize Crashlytics
    await _initializeCrashlytics();
    _logger.d('Crashlytics initialized');

    final database = await Database.initializeDatabase('kitchen_inventory.db');
    _logger.d('Database initialized');

    final errorHandler = ErrorHandler(navigatorKey: navigatorKey);
    final storageRepository = StorageRepository(database: database);
    final inventoryService = InventoryService(
      storageRepository: storageRepository,
    );

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((
      _,
    ) {
      _logger.i('Application ready, starting UI');
      runApp(
        MyApp(
          errorHandler: errorHandler,
          storageRepository: storageRepository,
          inventoryService: inventoryService,
        ),
      );
    });
  } catch (e, stackTrace) {
    _logger.wtf('Failed to initialize application', e, stackTrace);
    // Show some fallback UI or rethrow
    rethrow;
  }
}

Future<void> _initializeCrashlytics() async {
  // Pass all uncaught errors from the framework to Crashlytics
  final crashlytics = FirebaseCrashlytics.instance;

  // Force enable Crashlytics collection in debug mode for testing
  await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);

  // Set user identifier (useful for tracking specific user issues)
  // This would typically be set after user login
  // await crashlytics.setUserIdentifier('user123');

  // Add custom keys for additional context
  await crashlytics.setCustomKey('app_version', '1.0.0');
  await crashlytics.setCustomKey(
    'build_type',
    kDebugMode ? 'debug' : 'release',
  );

  // Log a message to indicate Crashlytics is initialized
  await crashlytics.log('Crashlytics initialized');
}

class MyApp extends StatelessWidget {
  final ErrorHandler errorHandler;
  final StorageRepository storageRepository;
  final InventoryService inventoryService;

  const MyApp({
    super.key,
    required this.errorHandler,
    required this.storageRepository,
    required this.inventoryService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider<ErrorHandler>.value(value: errorHandler),
        Provider<StorageRepository>.value(value: storageRepository),
        Provider<InventoryService>.value(value: inventoryService),
      ],
      child: MaterialApp(
        title: 'Kitchen Inventory',
        theme: AppTheme.lightTheme(),
        darkTheme: AppTheme.darkTheme(),
        themeMode: ThemeMode.system, // Respect system theme setting
        navigatorKey: navigatorKey,
        home: AuthWrapper(),
        routes: {
          SignInScreen.routeName: (context) => SignInScreen(),
          SignUpScreen.routeName: (context) => SignUpScreen(),
          InventoryScreen.routeName: (context) => InventoryScreen(),
          RecipeRecommendationsScreen.routeName:
              (context) => RecipeRecommendationsScreen(),
        },
      ),
    );
  }
}
