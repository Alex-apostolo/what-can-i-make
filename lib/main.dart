import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:what_can_i_make/core/database/database.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'data/repositories/storage_repository.dart';
import 'core/error/error_handler.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'features/auth/domain/auth_service.dart';
import 'features/auth/presentation/auth_wrapper.dart';
import 'features/auth/presentation/sign_in_screen.dart';
import 'features/auth/presentation/sign_up_screen.dart';
import 'features/inventory/domain/inventory_service.dart';
import 'features/inventory/presentation/inventory_screen.dart';
import 'features/recipes/presentation/recipe_recommendations_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final database = await Database.initializeDatabase('kitchen_inventory.db');
  final errorHandler = ErrorHandler(navigatorKey: navigatorKey);
  final storageRepository = StorageRepository(database: database);
  final inventoryService = InventoryService(
    storageRepository: storageRepository,
  );

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then(
    (_) => runApp(
      MyApp(
        errorHandler: errorHandler,
        storageRepository: storageRepository,
        inventoryService: inventoryService,
      ),
    ),
  );
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
