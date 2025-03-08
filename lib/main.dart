import 'package:flutter/material.dart';
import 'package:provider/single_child_widget.dart';
import 'package:what_can_i_make/core/utils/logger.dart';
import 'theme/app_theme.dart';
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
import 'features/user/presentation/account_screen.dart';
import 'package:what_can_i_make/features/user/domain/request_limit_service.dart';
import 'features/payment/domain/payment_service.dart';
import 'features/payment/presentation/payment_screen.dart';

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
        inventoryService: services.inventoryService,
        requestLimitService: services.requestLimitService,
        authService: services.authService,
        paymentService: services.paymentService,
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
  final InventoryService inventoryService;
  final RequestLimitService requestLimitService;
  final AuthService authService;
  final PaymentService paymentService;

  const MyApp({
    super.key,
    required this.errorHandler,
    required this.inventoryService,
    required this.requestLimitService,
    required this.authService,
    required this.paymentService,
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
      ChangeNotifierProvider(create: (_) => authService),
      Provider<ErrorHandler>.value(value: errorHandler),
      Provider<InventoryService>.value(value: inventoryService),
      ChangeNotifierProvider<RequestLimitService>.value(
        value: requestLimitService,
      ),
      ChangeNotifierProvider<PaymentService>.value(value: paymentService),
    ];
  }

  Map<String, WidgetBuilder> _buildRoutes() {
    return {
      SignInScreen.routeName: (context) => const SignInScreen(),
      SignUpScreen.routeName: (context) => const SignUpScreen(),
      InventoryScreen.routeName: (context) => const InventoryScreen(),
      RecipeRecommendationsScreen.routeName:
          (context) => const RecipeRecommendationsScreen(),
      AccountScreen.routeName: (context) => const AccountScreen(),
      PaymentScreen.routeName: (context) => const PaymentScreen(),
    };
  }
}
