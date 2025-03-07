import 'package:dartz/dartz.dart';
import 'package:what_can_i_make/features/categories/domain/ingredient_combiner_service.dart';
import 'package:what_can_i_make/core/error/failures/failure.dart';
import 'package:what_can_i_make/core/models/ingredient.dart';
import 'package:what_can_i_make/data/repositories/storage_repository.dart';

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
    List<IngredientInput> newIngredients,
  ) async {
    final result = await _storageRepository.addIngredients(newIngredients);

    return result.fold((failure) => Left(failure), (_) => _tidyIngredients());
  }

  /// Deletes an item
  Future<Either<Failure, void>> deleteIngredient(Ingredient ingredient) async {
    return _storageRepository.removeIngredient(ingredient);
  }

  /// Clears all inventory items
  Future<Either<Failure, void>> clearIngredients() async {
    return _storageRepository.clearIngredients();
  }

  // Tidies the inventory, removing duplicates and combining quantities
  Future<Either<Failure, void>> _tidyIngredients() async {
    final result = await _storageRepository.getIngredients();

    if (result.isLeft()) {
      return Left(GenericFailure(Exception(result)));
    }

    final combinedResult = await _ingredientCombinerService.combineIngredients(
      result.getOrElse(() => []),
    );

    if (combinedResult.isLeft()) {
      return Left(GenericFailure(Exception(combinedResult)));
    }

    final tidyIngredients = combinedResult.getOrElse(() => []);

    return _storageRepository.addIngredients(
      tidyIngredients.map((ingredient) => ingredient.toJson()).toList()
          as List<IngredientInput>,
    );
  }
}
