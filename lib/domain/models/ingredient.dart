class Ingredient {
  final String id;
  final String name;
  final String? brand;
  final int quantity;
  final String unit;

  const Ingredient({
    required this.id,
    required this.name,
    this.brand,
    required this.quantity,
    required this.unit,
  });

  Ingredient copyWith({
    String? id,
    String? name,
    String? brand,
    int? quantity,
    String? unit,
  }) {
    return Ingredient(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'quantity': quantity,
      'unit': unit,
    };
  }

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['id'],
      name: json['name'],
      brand: json['brand'],
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
        other.brand == brand &&
        other.quantity == quantity &&
        other.unit == unit;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, brand, quantity, unit);
  }
}
