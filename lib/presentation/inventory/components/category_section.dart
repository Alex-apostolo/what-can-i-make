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
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
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
              vertical: 12.0,
            ),
            decoration: BoxDecoration(
              color: _getCategoryColor(title).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8.0),
                topRight: Radius.circular(8.0),
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
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _getCategoryColor(title),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(title).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${items.length}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getCategoryColor(title),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Item list
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
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
        return Colors.green.shade700;
      case 'utensils':
        return Colors.blue.shade700;
      case 'equipment':
        return Colors.orange.shade700;
      default:
        return Colors.grey.shade700;
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
