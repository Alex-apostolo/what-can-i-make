import 'package:flutter/material.dart';
import '../../../domain/models/kitchen_item.dart';
import 'category_section.dart';

class InventoryList extends StatelessWidget {
  final List<(String, List<KitchenItem>)> categories;
  final Function(KitchenItem) onEdit;
  final Function(KitchenItem) onDelete;

  const InventoryList({
    super.key,
    required this.categories,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        for (final (title, items) in categories)
          if (items.isNotEmpty)
            CategorySection(
              title: title,
              items: items,
              onEdit: onEdit,
              onDelete: onDelete,
            ),
      ],
    );
  }
} 