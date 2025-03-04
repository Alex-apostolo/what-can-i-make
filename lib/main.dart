import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'presentation/theme/app_theme.dart';
import 'data/repositories/storage_repository.dart';
import 'core/error/error_handler.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'domain/services/auth_service.dart';
import 'presentation/auth/auth_wrapper.dart';
import 'presentation/auth/sign_in_screen.dart';
import 'presentation/auth/sign_up_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final storageRepository = await StorageRepository.initialize();

  // Set up global error handler
  errorHandler.showError = (failure) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(failure.message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.fixed,
        ),
      );
    }
  };

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]).then((_) => runApp(MyApp(storageRepository: storageRepository)));
}

// Add a global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  final StorageRepository storageRepository;

  const MyApp({super.key, required this.storageRepository});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provide AuthService
        ChangeNotifierProvider(create: (_) => AuthService()),

        // Provide StorageRepository
        Provider<StorageRepository>.value(value: storageRepository),
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
