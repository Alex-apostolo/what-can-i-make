import 'package:what_can_i_make/core/error/error_handler.dart';
import 'package:what_can_i_make/features/inventory/data/inventory_repository.dart';
import 'package:what_can_i_make/features/user/data/user_repository.dart';
import 'package:what_can_i_make/features/inventory/domain/inventory_service.dart';
import 'package:what_can_i_make/features/user/domain/request_limit_service.dart';
import 'package:what_can_i_make/features/auth/domain/auth_service.dart';

class AppServices {
  final ErrorHandler errorHandler;
  final InventoryRepository inventoryRepository;
  final UserRepository userRepository;
  final InventoryService inventoryService;
  final RequestLimitService requestLimitService;
  final AuthService authService;

  AppServices({
    required this.errorHandler,
    required this.inventoryRepository,
    required this.userRepository,
    required this.inventoryService,
    required this.requestLimitService,
    required this.authService,
  });
}
