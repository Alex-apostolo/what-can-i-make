class KitchenItem {
  final String id;
  final String name;
  final String category;
  final String? quantity;
  final String? notes;

  KitchenItem({
    required this.id,
    required this.name,
    required this.category,
    this.quantity,
    this.notes,
  });

  KitchenItem copyWith({
    String? id,
    String? name,
    String? category,
    String? quantity,
    String? notes,
  }) {
    return KitchenItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'quantity': quantity,
      'notes': notes,
    };
  }

  factory KitchenItem.fromMap(Map<String, dynamic> map) {
    return KitchenItem(
      id: map['id'] as String,
      name: map['name'] as String,
      category: map['category'] as String,
      quantity: map['quantity'] as String?,
      notes: map['notes'] as String?,
    );
  }
}
