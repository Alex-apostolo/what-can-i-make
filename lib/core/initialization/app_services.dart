import 'package:what_can_i_make/core/error/error_handler.dart';
import 'package:what_can_i_make/data/repositories/storage_repository.dart';
import 'package:what_can_i_make/features/inventory/domain/inventory_service.dart';
import 'package:what_can_i_make/core/services/token_usage_service.dart';

class AppServices {
  final ErrorHandler errorHandler;
  final StorageRepository storageRepository;
  final InventoryService inventoryService;
  final TokenUsageService tokenUsageService;

  AppServices({
    required this.errorHandler,
    required this.storageRepository,
    required this.inventoryService,
    required this.tokenUsageService,
  });
}
