import 'package:dartz/dartz.dart';
import '../../core/error/failures/failure.dart';
import '../models/ingredient.dart';
import '../../data/repositories/ingredients_repository.dart';

/// Service to manage kitchen inventory operations
class InventoryService {
  final StorageRepository _storageRepository;

  InventoryService({required StorageRepository storageRepository})
    : _storageRepository = storageRepository;

  /// Loads inventory from storage
  Future<Either<Failure, List<Ingredient>>> getIngredients() async {
    return _storageRepository.getIngredients();
  }

  /// Updates an existing item
  Future<Either<Failure, void>> updateIngredient(
    Ingredient updatedIngredient,
  ) async {
    return _storageRepository.updateIngredient(updatedIngredient);
  }

  /// Adds a new item
  Future<Either<Failure, void>> addIngredient(Ingredient newIngredient) async {
    return _storageRepository.addIngredient(newIngredient);
  }

  /// Adds multiple items
  Future<Either<Failure, void>> addIngredients(List<Ingredient> newIngredients) async {
    return _storageRepository.addIngredients(newIngredients);
  }

  /// Deletes an item
  Future<Either<Failure, void>> deleteIngredient(Ingredient ingredient) async {
    return _storageRepository.removeIngredient(ingredient);
  }

  /// Clears all inventory items
  Future<Either<Failure, void>> clearIngredients() async {
    return _storageRepository.clearIngredients();
  }

  /// Disposes resources
  void dispose() {
    _storageRepository.close();
  }
}
