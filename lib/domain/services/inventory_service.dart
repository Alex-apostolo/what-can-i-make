import 'package:flutter/foundation.dart';
import '../../core/utils/generate_unique_id.dart';
import '../models/ingredient.dart';
import '../../data/repositories/storage_repository.dart';
import '../../core/error/error_handler.dart';

/// Service to manage kitchen inventory operations
class InventoryService {
  final StorageRepository _storageRepository;

  // Callback for when inventory changes
  final VoidCallback onInventoryChanged;

  InventoryService({
    required this.onInventoryChanged,
    required StorageRepository storageRepository,
  }) : _storageRepository = storageRepository;

  /// Loads inventory from storage
  Future<List<Ingredient>> loadInventory() async {
    final result = await _storageRepository.getInventory();

    return result.fold(
      (failure) {
        errorHandler.handleFailure(failure);
        return <Ingredient>[];
      },
      (items) {
        items.sort(
          (a, b) =>
              getTimestampFromId(b.id).compareTo(getTimestampFromId(a.id)),
        );
        return items;
      },
    );
  }

  /// Updates an existing item
  Future<void> updateItem(Ingredient updatedItem) async {
    final result = await _storageRepository.updateItem(updatedItem);

    errorHandler.handleEither(result, onSuccess: (_) => onInventoryChanged());
  }

  /// Adds a new item
  Future<void> addItem(Ingredient newItem) async {
    final result = await _storageRepository.addItem(newItem);

    errorHandler.handleEither(result, onSuccess: (_) => onInventoryChanged());
  }

  /// Deletes an item
  Future<void> deleteItem(Ingredient item) async {
    final result = await _storageRepository.removeItem(item);

    errorHandler.handleEither(result, onSuccess: (_) => onInventoryChanged());
  }

  /// Clears all inventory items
  Future<void> clearInventory() async {
    final result = await _storageRepository.clearInventory();

    errorHandler.handleEither(result, onSuccess: (_) => onInventoryChanged());
  }

  /// Disposes resources
  void dispose() {
    _storageRepository.close();
  }
}
