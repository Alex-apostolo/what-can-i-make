import 'package:dartz/dartz.dart';
import 'package:what_can_i_make/domain/services/ingredient_combiner_service.dart';
import '../../core/error/failures/failure.dart';
import '../models/ingredient.dart';
import '../../data/repositories/ingredients_repository.dart';

/// Service to manage kitchen inventory operations
class InventoryService {
  late final StorageRepository _storageRepository;
  late final IngredientCombinerService _ingredientCombinerService;

  InventoryService({required StorageRepository storageRepository}) {
    _ingredientCombinerService = IngredientCombinerService();
    _storageRepository = storageRepository;
  }

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

  /// Adds multiple items
  Future<Either<Failure, void>> addIngredients(
    List<Ingredient> newIngredients,
  ) async {
    // Get existing ingredients
    final existingInventoryResult = await _storageRepository.getIngredients();

    return existingInventoryResult.fold((failure) => Left(failure), (
      existingInventory,
    ) async {
      // Combine new and existing ingredients
      final combinedInventoryResult = await _ingredientCombinerService
          .getCombinedIngredients(
            newIngredients: newIngredients,
            existingInventory: existingInventory,
          );

      return combinedInventoryResult.fold((failure) => Left(failure), (
        combinedInventory,
      ) async {
        // Clear old inventory and add combined ingredients
        await _storageRepository.clearIngredients();
        return _storageRepository.addIngredients(combinedInventory);
      });
    });
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
