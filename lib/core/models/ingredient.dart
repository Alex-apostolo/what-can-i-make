import 'measurement_unit.dart';
import 'ingredient_category.dart';

class Ingredient {
  final String id;
  final String name;
  final int quantity;
  final MeasurementUnit unit;
  final IngredientCategory category;
  final DateTime createdAt;

  const Ingredient({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.category,
    required this.createdAt,
  });

  /// Get the appropriate unit label based on quantity
  String get unitLabel {
    // For quantities of 1, use singular form
    if (quantity == 1) {
      return unit.label;
    }
    // For quantities other than 1, use plural form
    return unit.plural;
  }

  /// Create a copy of this Ingredient with the given fields replaced with the new values
  Ingredient copyWith({
    String? id,
    String? name,
    int? quantity,
    MeasurementUnit? unit,
    IngredientCategory? category,
    DateTime? createdAt,
  }) {
    return Ingredient(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Convert this Ingredient to a Map for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'unit': unit.label,
      'category': category.displayName,
      'createdAt': createdAt,
    };
  }

  /// Create an Ingredient from a Map (from storage)
  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['id'],
      name: json['name'],
      quantity: json['quantity'],
      unit: MeasurementUnit.fromString(json['unit'] ?? 'piece'),
      category: IngredientCategory.fromString(json['category'] ?? 'Other'),
      createdAt: json['createdAt'],
    );
  }
}

class IngredientInput {
  final String name;
  final int quantity;
  final MeasurementUnit unit;
  final IngredientCategory category;

  IngredientInput({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.category,
  });

  /// Convert this IngredientInput to a Map for storage
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'unit': unit.label,
      'category': category.displayName,
    };
  }

  /// Create an IngredientInput from a Map (from storage)
  factory IngredientInput.fromJson(Map<String, dynamic> json) {
    return IngredientInput(
      name: json['name'],
      quantity: json['quantity'],
      unit: MeasurementUnit.fromString(json['unit'] ?? 'piece'),
      category: IngredientCategory.fromString(json['category'] ?? 'Other'),
    );
  }
}
