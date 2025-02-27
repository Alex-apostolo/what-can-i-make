import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/home_screen.dart';
import 'services/storage_service.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: '.env');
    final storageService = await StorageService.initialize();

    runApp(MyApp(storageService: storageService));
  } catch (e) {
    print('Error initializing app: $e');
    // You might want to show an error screen here
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              'Error initializing app. Please check your configuration.',
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  final StorageService storageService;

  const MyApp({super.key, required this.storageService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kitchen Inventory',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: HomeScreen(storageService: storageService),
    );
  }
}
