class Ingredient {
  final String id;
  final String name;
  final double quantity;
  final String unit;

  const Ingredient({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
  });

  Ingredient copyWith({
    String? id,
    String? name,
    double? quantity,
    String? unit,
  }) {
    return Ingredient(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'quantity': quantity, 'unit': unit};
  }

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['id'],
      name: json['name'],
      quantity: json['quantity'],
      unit: json['unit'],
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
