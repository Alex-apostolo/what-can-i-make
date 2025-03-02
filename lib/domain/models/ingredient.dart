import 'measurement_unit.dart';

class Ingredient {
  final String id;
  final String name;
  final int quantity;
  final MeasurementUnit unit;

  const Ingredient({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
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

  Ingredient copyWith({
    String? id,
    String? name,
    int? quantity,
    MeasurementUnit? unit,
  }) {
    return Ingredient(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'quantity': quantity, 'unit': unit.label};
  }

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['id'],
      name: json['name'],
      quantity: json['quantity'],
      unit: MeasurementUnit.fromString(json['unit'] ?? 'piece'),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Ingredient &&
        other.id == id &&
        other.name == name &&
        other.quantity == quantity &&
        other.unit == unit;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, quantity, unit);
  }
}
