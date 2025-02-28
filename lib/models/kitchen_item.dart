class KitchenItem {
  final String id;
  final String name;
  final String category;
  final int? quantity;
  final DateTime createdAt;

  KitchenItem({
    required this.id,
    required this.name,
    required this.category,
    this.quantity,
  }) : createdAt = DateTime.now();

  KitchenItem copyWith({
    String? id,
    String? name,
    String? category,
    int? quantity,
  }) {
    return KitchenItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'category': category, 'quantity': quantity};
  }

  factory KitchenItem.fromMap(Map<String, dynamic> map) {
    return KitchenItem(
      id: map['id'] as String,
      name: map['name'] as String,
      category: map['category'] as String,
      quantity:
          map['quantity'] != null
              ? int.tryParse(map['quantity'].toString()) ?? 1
              : null,
    );
  }
}
