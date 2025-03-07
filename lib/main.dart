import 'package:flutter/material.dart';
import 'package:provider/single_child_widget.dart';
import 'package:what_can_i_make/core/utils/logger.dart';
import 'theme/app_theme.dart';
import 'data/repositories/storage_repository.dart';
import 'core/error/error_handler.dart';
import 'package:provider/provider.dart';
import 'features/auth/domain/auth_service.dart';
import 'features/auth/presentation/auth_wrapper.dart';
import 'features/auth/presentation/sign_in_screen.dart';
import 'features/auth/presentation/sign_up_screen.dart';
import 'features/inventory/domain/inventory_service.dart';
import 'features/inventory/presentation/inventory_screen.dart';
import 'features/recipes/presentation/recipe_recommendations_screen.dart';
import 'package:what_can_i_make/core/initialization/app_initializer.dart';
import 'features/auth/presentation/account_screen.dart';
import 'package:what_can_i_make/core/services/request_limit_service.dart';

// Global navigator key for app-wide navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Global logger instance
final AppLogger _logger = AppLogger();

void main() async {
  try {
    final initializer = AppInitializer(
      navigatorKey: navigatorKey,
      logger: _logger,
    );

    final services = await initializer.initialize();

    // Launch the app
    _logger.i('Application ready, starting UI');
    runApp(
      MyApp(
        errorHandler: services.errorHandler,
        storageRepository: services.storageRepository,
        inventoryService: services.inventoryService,
        requestLimitService: services.requestLimitService,
      ),
    );
  } catch (e, stackTrace) {
    _logger.f(
      'Failed to initialize application',
      error: e,
      stackTrace: stackTrace,
    );
    rethrow;
  }
}

class MyApp extends StatelessWidget {
  final ErrorHandler errorHandler;
  final StorageRepository storageRepository;
  final InventoryService inventoryService;
  final RequestLimitService requestLimitService;

  const MyApp({
    super.key,
    required this.errorHandler,
    required this.storageRepository,
    required this.inventoryService,
    required this.requestLimitService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: _buildProviders(),
      child: MaterialApp(
        title: 'Kitchen Inventory',
        theme: AppTheme.lightTheme(),
        darkTheme: AppTheme.darkTheme(),
        themeMode: ThemeMode.system, // Respect system theme setting
        navigatorKey: navigatorKey,
        home: AuthWrapper(),
        routes: _buildRoutes(),
      ),
    );
  }

  List<SingleChildWidget> _buildProviders() {
    return [
      ChangeNotifierProvider(create: (_) => AuthService()),
      Provider<ErrorHandler>.value(value: errorHandler),
      Provider<StorageRepository>.value(value: storageRepository),
      Provider<InventoryService>.value(value: inventoryService),
      ChangeNotifierProvider<RequestLimitService>.value(
        value: requestLimitService,
      ),
    ];
  }

  Map<String, WidgetBuilder> _buildRoutes() {
    return {
      SignInScreen.routeName: (context) => SignInScreen(),
      SignUpScreen.routeName: (context) => SignUpScreen(),
      InventoryScreen.routeName: (context) => InventoryScreen(),
      RecipeRecommendationsScreen.routeName:
          (context) => RecipeRecommendationsScreen(),
      AccountScreen.routeName: (context) => AccountScreen(),
    };
  }
}
