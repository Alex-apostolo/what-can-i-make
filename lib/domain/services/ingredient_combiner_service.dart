import 'package:dartz/dartz.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:what_can_i_make/domain/models/measurement_unit.dart';
import '../../core/error/failures/failure.dart';
import '../models/ingredient.dart';

class IngredientCombinerService {
  /// Combines ingredients with similar names and adds their quantities
  Future<Either<Failure, List<Ingredient>>> combineIngredients(
    List<Ingredient> ingredients,
  ) async {
    try {
      if (ingredients.isEmpty) {
        return const Right([]);
      }

      final combinedIngredients = <Ingredient>[];
      final processedIds = <String>{};

      // Sort ingredients by name to process similar ones together
      final sortedIngredients = List<Ingredient>.from(ingredients)
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      for (final ingredient in sortedIngredients) {
        // Skip if already processed
        if (processedIds.contains(ingredient.id)) continue;

        // Find similar ingredients
        final similarIngredients = _findSimilarIngredients(
          ingredient,
          sortedIngredients,
          processedIds,
        );

        // Combine them
        final combinedIngredient = _combineIngredientGroup([
          ingredient,
          ...similarIngredients,
        ]);

        // Mark all as processed
        processedIds.add(ingredient.id);
        for (final similar in similarIngredients) {
          processedIds.add(similar.id);
        }

        combinedIngredients.add(combinedIngredient);
      }

      return Right(combinedIngredients);
    } catch (e) {
      print('Error combining ingredients: $e');
      return Left(ParsingFailure());
    }
  }

  /// Finds ingredients with similar names using fuzzy matching
  List<Ingredient> _findSimilarIngredients(
    Ingredient target,
    List<Ingredient> allIngredients,
    Set<String> processedIds,
  ) {
    final similarIngredients = <Ingredient>[];
    final targetName = target.name.toLowerCase();

    for (final ingredient in allIngredients) {
      // Skip if it's the same ingredient or already processed
      if (ingredient.id == target.id || processedIds.contains(ingredient.id)) {
        continue;
      }

      final name = ingredient.name.toLowerCase();

      // Use fuzzy matching to determine similarity
      final ratio = partialRatio(targetName, name);
      if (ratio > 80) {
        // Threshold for similarity (0-100)
        similarIngredients.add(ingredient);
      }
    }

    return similarIngredients;
  }

  /// Combines a group of similar ingredients
  Ingredient _combineIngredientGroup(List<Ingredient> group) {
    if (group.isEmpty) {
      throw ArgumentError('Cannot combine empty group');
    }

    if (group.length == 1) {
      return group.first;
    }

    // Choose the most descriptive name (usually the longest)
    final sortedByNameLength = List<Ingredient>.from(group)
      ..sort((a, b) => b.name.length.compareTo(a.name.length));

    final base = sortedByNameLength.first;

    // For simplicity, just use the largest unit found
    final largestUnit = _findLargestUnit(group);

    // Combine quantities with unit conversion
    double totalQuantity = 0;

    for (final ingredient in group) {
      final convertedQuantity = _convertToBestUnit(
        ingredient.quantity.toDouble(),
        ingredient.unit.name,
        largestUnit,
        ingredient.name,
      );

      if (convertedQuantity != null) {
        totalQuantity += convertedQuantity;
      } else {
        print(
          'Could not convert ${ingredient.unit.name} to $largestUnit for ${ingredient.name}',
        );
        // If we can't convert, we'll just skip adding this quantity for simplicity
      }
    }

    return Ingredient(
      id: base.id,
      name: base.name,
      category: base.category,
      quantity: totalQuantity.round(),
      unit: MeasurementUnit.fromString(_normalizeUnitName(largestUnit)),
    );
  }

  /// Finds the largest unit among a group of ingredients
  String _findLargestUnit(List<Ingredient> group) {
    // Unit size hierarchy (from largest to smallest)
    final weightHierarchy = ['kg', 'lb', 'g', 'oz'];
    final volumeHierarchy = ['l', 'cup', 'tbsp', 'tsp', 'ml'];

    // Collect all normalized unit names
    final units = group.map((i) => _normalizeUnitName(i.unit.name)).toSet();

    // Check weight units first
    for (final unit in weightHierarchy) {
      if (units.contains(unit)) {
        return unit;
      }
    }

    // Then check volume units
    for (final unit in volumeHierarchy) {
      if (units.contains(unit)) {
        return unit;
      }
    }

    // If no standard units found, return the first ingredient's unit
    return _normalizeUnitName(group.first.unit.name);
  }

  /// Simple conversion between units of the same type
  double? _convertToBestUnit(
    double quantity,
    String fromUnit,
    String toUnit,
    String ingredientName,
  ) {
    // Normalize unit names
    final normalizedFromUnit = _normalizeUnitName(fromUnit);
    final normalizedToUnit = _normalizeUnitName(toUnit);

    // If units are the same, no conversion needed
    if (normalizedFromUnit == normalizedToUnit) {
      return quantity;
    }

    // For simplicity, we'll only handle same-unit-type conversions
    // with basic conversion factors
    final conversions = {
      // Weight conversions
      'kg': {'g': 1000, 'kg': 1},
      'g': {'kg': 0.001, 'g': 1},
      'lb': {'oz': 16, 'lb': 1},
      'oz': {'lb': 0.0625, 'oz': 1},

      // Volume conversions
      'l': {'ml': 1000, 'l': 1},
      'ml': {'l': 0.001, 'ml': 1},
      'cup': {'tbsp': 16, 'tsp': 48, 'cup': 1},
      'tbsp': {'tsp': 3, 'cup': 0.0625, 'tbsp': 1},
      'tsp': {'tbsp': 0.333, 'cup': 0.0208, 'tsp': 1},
    };

    // Check if we have a conversion factor
    if (conversions.containsKey(normalizedFromUnit) &&
        conversions[normalizedFromUnit]!.containsKey(normalizedToUnit)) {
      return quantity * conversions[normalizedFromUnit]![normalizedToUnit]!;
    }

    // If no conversion found, return null
    return null;
  }

  /// Add this method to normalize unit names
  String _normalizeUnitName(String unitName) {
    // Map full unit names to abbreviations
    final unitMap = {
      'gram': 'g',
      'grams': 'g',
      'kilogram': 'kg',
      'kilograms': 'kg',
      'ounce': 'oz',
      'ounces': 'oz',
      'pound': 'lb',
      'pounds': 'lb',
      'milliliter': 'ml',
      'milliliters': 'ml',
      'liter': 'l',
      'liters': 'l',
      'L': 'l',
      'cup': 'cup',
      'cups': 'cup',
      'tablespoon': 'tbsp',
      'tablespoons': 'tbsp',
      'teaspoon': 'tsp',
      'teaspoons': 'tsp',
      'whole': 'whole',
      'piece': 'piece',
      'pieces': 'piece',
      'clove': 'clove',
      'cloves': 'clove',
    };

    return unitMap[unitName.toLowerCase()] ?? unitName.toLowerCase();
  }
}
