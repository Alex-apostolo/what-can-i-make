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

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final database = await Database.initializeDatabase('kitchen_inventory.db');
  final storageRepository = StorageRepository(database: database);
  final errorHandler = ErrorHandler(navigatorKey: navigatorKey);

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then(
    (_) => runApp(
      MyApp(storageRepository: storageRepository, errorHandler: errorHandler),
    ),
  );
}

class MyApp extends StatelessWidget {
  final StorageRepository storageRepository;
  final ErrorHandler errorHandler;

  const MyApp({
    super.key,
    required this.storageRepository,
    required this.errorHandler,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider<StorageRepository>.value(value: storageRepository),
        Provider<ErrorHandler>.value(value: errorHandler),
      ],
      child: MaterialApp(
        title: 'Kitchen Inventory',
        theme: AppTheme.lightTheme(),
        darkTheme: AppTheme.darkTheme(),
        themeMode: ThemeMode.system, // Respect system theme setting
        navigatorKey: navigatorKey,
        home: AuthWrapper(),
        routes: {
          SignInScreen.routeName: (ctx) => SignInScreen(),
          SignUpScreen.routeName: (ctx) => SignUpScreen(),
        },
      ),
    );
  }
}
