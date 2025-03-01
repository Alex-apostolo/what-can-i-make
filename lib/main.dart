import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'presentation/inventory/inventory_screen.dart';
import 'data/repositories/storage_repository.dart';
import 'core/error/error_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
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

  runApp(MyApp(storageRepository: storageRepository));
}

// Add a global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  final StorageRepository storageRepository;
  
  const MyApp({super.key, required this.storageRepository});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kitchen Inventory',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF64B5F6)),
        useMaterial3: true,
      ),
      navigatorKey: navigatorKey,
      home: InventoryScreen(storageRepository: storageRepository),
    );
  }
}
