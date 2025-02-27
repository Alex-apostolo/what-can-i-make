import 'package:flutter/material.dart';
import '../models/kitchen_item.dart';

class ItemCard extends StatelessWidget {
  final KitchenItem item;
  final Function(KitchenItem) onEdit;
  final Function(KitchenItem) onDelete;

  const ItemCard({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(item.name),
        subtitle:
            item.quantity != null || item.notes != null
                ? Text(
                  [
                    if (item.quantity != null) 'Quantity: ${item.quantity}',
                    if (item.notes != null) 'Notes: ${item.notes}',
                  ].join('\n'),
                )
                : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => onEdit(item),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => onDelete(item),
            ),
          ],
        ),
      ),
    );
  }
}
