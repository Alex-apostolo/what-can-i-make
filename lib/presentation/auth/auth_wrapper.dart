import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:what_can_i_make/data/repositories/storage_repository.dart';
import '../../domain/services/auth_service.dart';
import '../../domain/services/inventory_service.dart';
import '../inventory/inventory_screen.dart';
import 'sign_in_screen.dart';

// Set to false when you need to test auth
const bool bypassAuth = true;

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final storageRepository = context.read<StorageRepository>();

    // For development, bypass authentication
    if (kDebugMode && bypassAuth) {
      return _wrapWithInventoryService(
        storageRepository,
        const InventoryScreen(),
      );
    }

    // Normal authentication flow
    final authService = context.watch<AuthService>();

    if (authService.currentUser == null) {
      return SignInScreen();
    } else {
      return _wrapWithInventoryService(
        storageRepository,
        const InventoryScreen(),
      );
    }
  }

  // Helper method to avoid code duplication
  Widget _wrapWithInventoryService(
    StorageRepository storageRepository,
    Widget child,
  ) {
    return Provider<InventoryService>(
      create: (_) => InventoryService(storageRepository: storageRepository),
      child: child,
    );
  }
}
