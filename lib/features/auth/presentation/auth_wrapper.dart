import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:what_can_i_make/features/auth/domain/auth_service.dart';
import 'package:what_can_i_make/features/inventory/presentation/inventory_screen.dart';
import 'sign_in_screen.dart';

// Set to false when you need to test auth
const bool bypassAuth = true;

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // For development, bypass authentication
    if (kDebugMode && bypassAuth) {
      return InventoryScreen();
    }

    // Normal authentication flow
    final authService = context.watch<AuthService>();

    if (authService.currentUser == null) {
      return SignInScreen();
    } else {
      return InventoryScreen();
    }
  }
}
