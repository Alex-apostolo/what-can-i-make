import 'package:flutter/foundation.dart';
import '../../domain/models/kitchen_item.dart';
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
  Future<List<KitchenItem>> loadInventory() async {
    final result = await _storageRepository.getInventory();
    
    return result.fold(
      (failure) {
        errorHandler.handleFailure(failure);
        return <KitchenItem>[];
      },
      (items) => items,
    );
  }
  
  /// Updates an existing item
  Future<void> updateItem(KitchenItem updatedItem) async {
    final result = await _storageRepository.updateItem(updatedItem);
    
    errorHandler.handleEither(
      result,
      onSuccess: (_) => onInventoryChanged(),
    );
  }
  
  /// Adds a new item
  Future<void> addItem(KitchenItem newItem) async {
    final result = await _storageRepository.addItem(newItem);
    
    errorHandler.handleEither(
      result,
      onSuccess: (_) => onInventoryChanged(),
    );
  }
  
  /// Deletes an item
  Future<void> deleteItem(KitchenItem item) async {
    final result = await _storageRepository.removeItem(item);
    
    errorHandler.handleEither(
      result,
      onSuccess: (_) => onInventoryChanged(),
    );
  }
  
  /// Clears all inventory items
  Future<void> clearInventory() async {
    final result = await _storageRepository.clearInventory();
    
    errorHandler.handleEither(
      result,
      onSuccess: (_) => onInventoryChanged(),
    );
  }
  
  /// Organizes items into categories
  List<(String, List<KitchenItem>)> categorizeInventory(List<KitchenItem> inventory) {
    // Sort items by ID in reverse order (assuming ID is timestamp-based)
    final sortedInventory = List<KitchenItem>.from(inventory)
      ..sort((a, b) => b.id.compareTo(a.id));

    return [
      (
        'Ingredients',
        sortedInventory.where((item) => item.category == 'ingredient').toList(),
      ),
      (
        'Utensils',
        sortedInventory.where((item) => item.category == 'utensil').toList(),
      ),
      (
        'Equipment',
        sortedInventory.where((item) => item.category == 'equipment').toList(),
      ),
    ];
  }
  
  /// Disposes resources
  void dispose() {
    _storageRepository.close();
  }
} 