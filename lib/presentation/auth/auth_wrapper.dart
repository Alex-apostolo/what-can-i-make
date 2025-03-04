import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/services/auth_service.dart';
import '../inventory/inventory_screen.dart';
import 'sign_in_screen.dart';

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final storageRepository = Provider.of<StorageRepository>(context);

    // Show loading indicator while determining auth state
    if (authService.currentUser == null) {
      return SignInScreen();
    } else {
      return InventoryScreen(storageRepository: storageRepository); // Or your main app screen
    }
  }
}
