import 'package:flutter/material.dart';
import '../models/kitchen_item.dart';
import 'item_card.dart';

class CategorySection extends StatelessWidget {
  final String title;
  final List<KitchenItem> items;
  final Function(KitchenItem) onEdit;
  final Function(KitchenItem) onDelete;

  const CategorySection({
    super.key,
    required this.title,
    required this.items,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF424242),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getCategoryColor().withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${items.length}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _getCategoryColor(),
                  ),
                ),
              ),
            ],
          ),
        ),
        ...items.map(
          (item) => ItemCard(
            key: ValueKey(item.id),
            item: item,
            onEdit: () => onEdit(item),
            onDelete: () => onDelete(item),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Color _getCategoryColor() {
    switch (title.toLowerCase()) {
      case 'ingredients':
        return const Color(0xFF7CB342);
      case 'utensils':
        return const Color(0xFFFFB74D);
      case 'equipment':
        return const Color(0xFF64B5F6);
      default:
        return Colors.grey.shade400;
    }
  }
}
