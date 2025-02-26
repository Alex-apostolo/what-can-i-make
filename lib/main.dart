import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/home_screen.dart';
import 'screens/image_picker_screen.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  final storageService = await StorageService.initialize();

  runApp(MyApp(storageService: storageService));
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
      onGenerateRoute: (settings) {
        if (settings.name == '/add-items') {
          return MaterialPageRoute(
            builder:
                (context) => ImagePickerScreen(storageService: storageService),
          );
        }
        return null;
      },
    );
  }
}
