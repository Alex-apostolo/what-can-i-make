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

    // Combine quantities with unit conversion
    double totalQuantity = base.quantity.toDouble();
    String baseUnit = base.unit.name;

    for (int i = 1; i < group.length; i++) {
      final current = group[i];
      if (current.unit == baseUnit) {
        totalQuantity += current.quantity.toDouble();
      } else {
        // Try to convert units
        final convertedQuantity = _convertQuantity(
          current.quantity.toDouble(),
          current.unit.name,
          baseUnit,
          current.name,
        );

        if (convertedQuantity != null) {
          totalQuantity += convertedQuantity;
        } else {
          print(
            'Could not convert ${current.unit} to $baseUnit for ${current.name}',
          );
        }
      }
    }

    return Ingredient(
      id: base.id,
      name: base.name,
      category: base.category,
      quantity: totalQuantity.round(), // Convert back to int if needed
      unit: MeasurementUnit.fromString(baseUnit),
    );
  }

  /// Converts quantity between different units
  double? _convertQuantity(
    double quantity,
    String fromUnit,
    String toUnit,
    String ingredientName,
  ) {
    // Skip conversion if units are the same
    if (fromUnit == toUnit) return quantity;

    // Common weight conversions
    final weightConversions = {
      'g': {'kg': 0.001, 'oz': 0.035274, 'lb': 0.00220462},
      'kg': {'g': 1000, 'oz': 35.274, 'lb': 2.20462},
      'oz': {'g': 28.3495, 'kg': 0.0283495, 'lb': 0.0625},
      'lb': {'g': 453.592, 'kg': 0.453592, 'oz': 16},
    };

    // Common volume conversions
    final volumeConversions = {
      'ml': {'l': 0.001, 'cup': 0.00422675, 'tbsp': 0.067628, 'tsp': 0.202884},
      'l': {'ml': 1000, 'cup': 4.22675, 'tbsp': 67.628, 'tsp': 202.884},
      'cup': {'ml': 236.588, 'l': 0.236588, 'tbsp': 16, 'tsp': 48},
      'tbsp': {'ml': 14.7868, 'l': 0.0147868, 'cup': 0.0625, 'tsp': 3},
      'tsp': {
        'ml': 4.92892,
        'l': 0.00492892,
        'cup': 0.0208333,
        'tbsp': 0.333333,
      },
    };

    // Try weight conversions
    if (weightConversions.containsKey(fromUnit) &&
        weightConversions[fromUnit]!.containsKey(toUnit)) {
      return quantity * weightConversions[fromUnit]![toUnit]!;
    }

    // Try volume conversions
    if (volumeConversions.containsKey(fromUnit) &&
        volumeConversions[fromUnit]!.containsKey(toUnit)) {
      return quantity * volumeConversions[fromUnit]![toUnit]!;
    }

    // Special case for common ingredients
    if (_canEstimateConversion(ingredientName, fromUnit, toUnit)) {
      return _estimateIngredientConversion(
        ingredientName,
        quantity,
        fromUnit,
        toUnit,
      );
    }

    // Couldn't convert
    return null;
  }

  /// Checks if we can estimate a conversion for a specific ingredient
  bool _canEstimateConversion(
    String ingredientName,
    String fromUnit,
    String toUnit,
  ) {
    final name = ingredientName.toLowerCase();

    // Common conversions we can estimate
    final conversions = {
      'onion': {'whole': 'g'},
      'garlic': {'clove': 'g'},
      'tomato': {'whole': 'g'},
      'egg': {'whole': 'g'},
      'potato': {'whole': 'g'},
      'carrot': {'whole': 'g'},
      'apple': {'whole': 'g'},
    };

    return conversions.keys.any(
      (key) =>
          name.contains(key) &&
          conversions[key]!.containsKey(fromUnit) &&
          conversions[key]![fromUnit] == toUnit,
    );
  }

  /// Estimates conversion for specific ingredients
  double? _estimateIngredientConversion(
    String ingredientName,
    double quantity,
    String fromUnit,
    String toUnit,
  ) {
    final name = ingredientName.toLowerCase();

    // Average weights for common ingredients
    final weights = {
      'onion': {'whole': 150}, // 150g per onion
      'garlic': {'clove': 5}, // 5g per clove
      'tomato': {'whole': 120}, // 120g per tomato
      'egg': {'whole': 50}, // 50g per egg
      'potato': {'whole': 200}, // 200g per potato
      'carrot': {'whole': 60}, // 60g per carrot
      'apple': {'whole': 180}, // 180g per apple
    };

    for (final entry in weights.entries) {
      if (name.contains(entry.key) &&
          entry.value.containsKey(fromUnit) &&
          toUnit == 'g') {
        return quantity * entry.value[fromUnit]!;
      }
    }

    return null;
  }
}
