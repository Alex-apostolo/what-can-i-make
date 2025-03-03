import 'package:dartz/dartz.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:units_converter/units_converter.dart';
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

    // Determine the best unit to use (prefer larger units)
    final bestUnit = _determineBestUnit(group);

    // Combine quantities with unit conversion
    double totalQuantity = 0;

    for (final ingredient in group) {
      final convertedQuantity = _convertToBestUnit(
        ingredient.quantity.toDouble(),
        ingredient.unit.name,
        bestUnit,
        ingredient.name,
      );

      if (convertedQuantity != null) {
        totalQuantity += convertedQuantity;
      } else {
        print(
          'Could not convert ${ingredient.unit.name} to $bestUnit for ${ingredient.name}',
        );
        // If we can't convert, just add the original quantity if units match
        if (ingredient.unit.name == bestUnit) {
          totalQuantity += ingredient.quantity.toDouble();
        }
      }
    }

    return Ingredient(
      id: base.id,
      name: base.name,
      category: base.category,
      quantity: totalQuantity.round(),
      unit: MeasurementUnit.fromString(bestUnit),
    );
  }

  /// Determines the best unit to use for a group of ingredients
  String _determineBestUnit(List<Ingredient> group) {
    // Count unit frequencies
    final unitCounts = <String, int>{};
    for (final ingredient in group) {
      final unitName = ingredient.unit.name;
      unitCounts[unitName] = (unitCounts[unitName] ?? 0) + 1;
    }

    // If there's a dominant unit, use it
    final mostCommonUnit =
        unitCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    if (unitCounts[mostCommonUnit]! > group.length / 2) {
      return mostCommonUnit;
    }

    // Otherwise, try to find the largest unit that can represent all values
    final weightUnits = ['kg', 'g', 'lb', 'oz'];
    final volumeUnits = ['l', 'ml', 'cup', 'tbsp', 'tsp'];

    // Check if all units are weight units
    final allWeightUnits = group.every(
      (i) => weightUnits.contains(i.unit.name),
    );
    if (allWeightUnits) {
      // Prefer kg for large quantities, g for smaller
      final totalGrams = _estimateTotalInGrams(group);
      return totalGrams > 1000 ? 'kg' : 'g';
    }

    // Check if all units are volume units
    final allVolumeUnits = group.every(
      (i) => volumeUnits.contains(i.unit.name),
    );
    if (allVolumeUnits) {
      // Prefer l for large quantities, ml for smaller
      final totalMl = _estimateTotalInMilliliters(group);
      return totalMl > 1000 ? 'l' : 'ml';
    }

    // Default to the most common unit
    return mostCommonUnit;
  }

  /// Estimates the total quantity in grams
  double _estimateTotalInGrams(List<Ingredient> group) {
    double totalGrams = 0;
    for (final ingredient in group) {
      final grams = _convertToGrams(
        ingredient.quantity.toDouble(),
        ingredient.unit.name,
      );
      if (grams != null) {
        totalGrams += grams;
      }
    }
    return totalGrams;
  }

  /// Estimates the total quantity in milliliters
  double _estimateTotalInMilliliters(List<Ingredient> group) {
    double totalMl = 0;
    for (final ingredient in group) {
      final ml = _convertToMilliliters(
        ingredient.quantity.toDouble(),
        ingredient.unit.name,
      );
      if (ml != null) {
        totalMl += ml;
      }
    }
    return totalMl;
  }

  /// Converts a quantity to the best unit using units_converter
  double? _convertToBestUnit(
    double quantity,
    String fromUnit,
    String toUnit,
    String ingredientName,
  ) {
    // Skip conversion if units are the same
    if (fromUnit == toUnit) return quantity;

    try {
      // Try standard conversion with units_converter
      return _convertWithUnitsConverter(quantity, fromUnit, toUnit);
    } catch (e) {
      // If standard conversion fails, try our custom conversions
      return _fallbackConversion(quantity, fromUnit, toUnit, ingredientName);
    }
  }

  /// Converts to grams
  double? _convertToGrams(double quantity, String fromUnit) {
    return _convertWithUnitsConverter(quantity, fromUnit, 'g');
  }

  /// Converts to milliliters
  double? _convertToMilliliters(double quantity, String fromUnit) {
    return _convertWithUnitsConverter(quantity, fromUnit, 'ml');
  }

  /// Converts units using the units_converter package
  double? _convertWithUnitsConverter(
    double quantity,
    String fromUnit,
    String toUnit,
  ) {
    // Map our unit names to units_converter units
    final unitMap = {
      // Mass units
      'g': MASS.grams,
      'kg': MASS.kilograms,
      'oz': MASS.ounces,
      'lb': MASS.pounds,

      // Volume units
      'ml': VOLUME.milliliters,
      'l': VOLUME.liters,
      'cup': VOLUME.cups,
      'tbsp': VOLUME.tablespoonsUs,
      'tsp': VOLUME.teaspoonsUs,
    };

    // Check if we can convert between these units
    if (unitMap.containsKey(fromUnit) && unitMap.containsKey(toUnit)) {
      // Check if both units are of the same type (mass or volume)
      final fromUnitType = _getUnitType(fromUnit);
      final toUnitType = _getUnitType(toUnit);

      if (fromUnitType == toUnitType) {
        if (fromUnitType == 'mass') {
          return quantity.convertFromTo(
            unitMap[fromUnit] as MASS,
            unitMap[toUnit] as MASS,
          );
        } else if (fromUnitType == 'volume') {
          return quantity.convertFromTo(
            unitMap[fromUnit] as VOLUME,
            unitMap[toUnit] as VOLUME,
          );
        }
      }
    }

    return null;
  }

  /// Determines the type of unit (mass or volume)
  String _getUnitType(String unit) {
    final massUnits = ['g', 'kg', 'oz', 'lb'];
    final volumeUnits = ['ml', 'l', 'cup', 'tbsp', 'tsp'];

    if (massUnits.contains(unit)) {
      return 'mass';
    } else if (volumeUnits.contains(unit)) {
      return 'volume';
    } else {
      return 'unknown';
    }
  }

  /// Fallback conversion for cases units_converter doesn't handle
  double? _fallbackConversion(
    double quantity,
    String fromUnit,
    String toUnit,
    String ingredientName,
  ) {
    final name = ingredientName.toLowerCase();

    // Ingredient-specific conversions
    final specificConversions = {
      'onion': {
        'whole': {'g': 150},
      },
      'garlic': {
        'clove': {'g': 5},
      },
      'tomato': {
        'whole': {'g': 120},
      },
      'egg': {
        'whole': {'g': 50},
      },
      'potato': {
        'whole': {'g': 200},
      },
      'carrot': {
        'whole': {'g': 60},
      },
      'apple': {
        'whole': {'g': 180},
      },
    };

    // Check for ingredient-specific conversion
    for (final entry in specificConversions.entries) {
      if (name.contains(entry.key) &&
          entry.value.containsKey(fromUnit) &&
          entry.value[fromUnit]!.containsKey(toUnit)) {
        return quantity * entry.value[fromUnit]![toUnit]!;
      }
    }

    return null;
  }
}
