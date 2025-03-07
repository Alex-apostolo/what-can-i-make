import 'package:dartz/dartz.dart';
import 'package:what_can_i_make/features/categories/domain/ingredient_combiner_service.dart';
import 'package:what_can_i_make/core/error/failures/failure.dart';
import 'package:what_can_i_make/features/inventory/models/ingredient.dart';
import 'package:what_can_i_make/features/inventory/data/inventory_repository.dart';

/// Service to manage kitchen inventory operations
class InventoryService {
  late final InventoryRepository _inventoryRepository;
  late final IngredientCombinerService _ingredientCombinerService;

  InventoryService({required InventoryRepository inventoryRepository}) {
    _ingredientCombinerService = IngredientCombinerService();
    _inventoryRepository = inventoryRepository;
  }

  /// Loads inventory from storage
  Future<Either<Failure, List<Ingredient>>> getInventory() async {
    return _inventoryRepository.getInventory();
  }

  /// Updates an existing item
  Future<Either<Failure, void>> updateIngredient(
    Ingredient updatedIngredient,
  ) async {
    return _inventoryRepository.updateIngredient(updatedIngredient);
  }

  /// Adds multiple items
  Future<Either<Failure, void>> addIngredients(
    List<IngredientInput> newIngredients,
  ) async {
    final result = await _inventoryRepository.addIngredients(newIngredients);

    return result.fold((failure) => Left(failure), (_) => _tidyInventory());
  }

  /// Deletes an item
  Future<Either<Failure, void>> deleteIngredient(Ingredient ingredient) async {
    return _inventoryRepository.removeIngredient(ingredient);
  }

  /// Clears all inventory items
  Future<Either<Failure, void>> clearInventory() async {
    return _inventoryRepository.clearInventory();
  }

  // Tidies the inventory, removing duplicates and combining quantities
  Future<Either<Failure, void>> _tidyInventory() async {
    // Get all ingredients
    final result = await _inventoryRepository.getInventory();
    if (result.isLeft()) {
      return Left(GenericFailure(Exception(result)));
    }

    // Combine similar ingredients
    final combinedResult = await _ingredientCombinerService.combineIngredients(
      result.getOrElse(() => []),
    );
    if (combinedResult.isLeft()) {
      return Left(GenericFailure(Exception(combinedResult)));
    }

    // Clear existing ingredients and add the combined ones
    final tidyIngredients = combinedResult.getOrElse(() => []);
    final clearResult = await _inventoryRepository.clearInventory();
    if (clearResult.isLeft()) {
      return Left(GenericFailure(Exception(clearResult)));
    }

    // Convert Ingredient objects to IngredientInput objects
    return _inventoryRepository.addIngredients(
      tidyIngredients
          .map(
            (ingredient) => IngredientInput(
              name: ingredient.name,
              quantity: ingredient.quantity,
              unit: ingredient.unit,
              category: ingredient.category,
            ),
          )
          .toList(),
    );
  }
}
