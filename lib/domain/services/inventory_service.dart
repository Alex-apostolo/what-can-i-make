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
    final result = await _storageRepository.addIngredients(newIngredients);
    return result.fold(
      (failure) => Left(failure),
      (ingredients) => tidyIngredients(),
    );
  }

  /// Deletes an item
  Future<Either<Failure, void>> deleteIngredient(Ingredient ingredient) async {
    return _storageRepository.removeIngredient(ingredient);
  }

  /// Clears all inventory items
  Future<Either<Failure, void>> clearIngredients() async {
    return _storageRepository.clearIngredients();
  }

  /// Tidies the inventory, removing duplicates and combining quantities
  Future<Either<Failure, void>> tidyIngredients() async {
    final result = await getIngredients();
    return result.fold(
      (failure) => Left(failure),
      (existingInventory) =>
          _ingredientCombinerService.combineIngredients(existingInventory),
    );
  }

  /// Disposes resources
  void dispose() {
    _storageRepository.close();
  }
}
