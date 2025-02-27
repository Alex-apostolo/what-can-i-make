import 'package:flutter/material.dart';
import '../models/kitchen_item.dart';

class EditItemDialog extends StatelessWidget {
  final KitchenItem item;
  final Function(KitchenItem) onSave;

  const EditItemDialog({
    super.key,
    required this.item,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController(text: item.name);
    final quantityController = TextEditingController(text: item.quantity);

    return AlertDialog(
      title: const Text('Edit Item'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          TextField(
            controller: quantityController,
            decoration: const InputDecoration(labelText: 'Quantity'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final updatedItem = item.copyWith(
              name: nameController.text,
              quantity: quantityController.text,
            );
            onSave(updatedItem);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
} 