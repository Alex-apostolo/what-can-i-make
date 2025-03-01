import 'package:flutter/material.dart';
import '../../../domain/models/kitchen_item.dart';
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
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 14.0,
            ),
            decoration: BoxDecoration(
              color: _getCategoryColor(title).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12.0),
                topRight: Radius.circular(12.0),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getCategoryIcon(title),
                  color: _getCategoryColor(title),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _getCategoryColor(title),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(title).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${items.length}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getCategoryColor(title),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Item list
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  'No items in this category',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder:
                  (context, index) => Divider(
                    height: 1,
                    color: theme.dividerColor.withOpacity(0.5),
                  ),
              itemBuilder: (context, index) {
                return ItemCard(
                  item: items[index],
                  onEdit: onEdit,
                  onDelete: onDelete,
                );
              },
            ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'ingredients':
        return Colors.green.shade600;
      case 'utensils':
        return Colors.blue.shade600;
      case 'equipment':
        return Colors.orange.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'ingredients':
        return Icons.restaurant;
      case 'utensils':
        return Icons.flatware;
      case 'equipment':
        return Icons.blender;
      default:
        return Icons.category;
    }
  }
}
