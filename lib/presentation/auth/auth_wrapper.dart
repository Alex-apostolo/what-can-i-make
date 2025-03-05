import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:what_can_i_make/data/repositories/storage_repository.dart';
import '../../domain/services/auth_service.dart';
import '../../domain/services/inventory_service.dart';
import '../inventory/inventory_screen.dart';
import 'sign_in_screen.dart';

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final storageRepository = Provider.of<StorageRepository>(
      context,
      listen: false,
    );

    // Show loading indicator while determining auth state
    if (authService.currentUser == null) {
      return SignInScreen();
    } else {
      // Wrap InventoryScreen with a Provider for InventoryService
      return Provider<InventoryService>(
        create: (_) => InventoryService(storageRepository: storageRepository),
        child: InventoryScreen(),
      );
    }
  }
}
