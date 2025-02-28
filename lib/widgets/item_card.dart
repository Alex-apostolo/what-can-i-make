import 'package:flutter/material.dart';
import '../models/kitchen_item.dart';

class ItemCard extends StatelessWidget {
  final KitchenItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ItemCard({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _getCategoryColor().withAlpha(76), width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _buildQuantityBadge(),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          _getCategoryText(),
          style: TextStyle(
            color: _getCategoryColor().withAlpha(192),
            fontStyle: FontStyle.italic,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: Colors.blueGrey.shade400),
              onPressed: onEdit,
              tooltip: 'Edit item',
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.redAccent.shade200),
              onPressed: onDelete,
              tooltip: 'Delete item',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityBadge() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _getCategoryColor().withAlpha(50),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _getCategoryColor().withAlpha(120), width: 1),
      ),
      child: Center(
        child: Text(
          '${item.quantity ?? 1}',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: _getCategoryColor().withAlpha(144),
          ),
        ),
      ),
    );
  }

  String _getCategoryText() {
    switch (item.category) {
      case 'ingredient':
        return 'Ingredient';
      case 'utensil':
        return 'Utensil';
      case 'equipment':
        return 'Equipment';
      default:
        return item.category;
    }
  }

  Color _getCategoryColor() {
    switch (item.category) {
      case 'ingredient':
        return const Color(0xFF7CB342); // Softer green
      case 'utensil':
        return const Color(0xFFFFB74D); // Softer orange
      case 'equipment':
        return const Color(0xFF64B5F6); // Softer blue
      default:
        return Colors.grey.shade400;
    }
  }
}
