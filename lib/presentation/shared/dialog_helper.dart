import 'package:flutter/material.dart';
import '../../domain/models/kitchen_item.dart';
import '../inventory/dialogs/add_item_dialog.dart';
import '../inventory/dialogs/edit_item_dialog.dart';

class DialogHelper {
  /// Shows dialog to edit an item
  static Future<void> showEditDialog(
    BuildContext context,
    KitchenItem item,
    Function(KitchenItem) onSave,
  ) {
    return showDialog(
      context: context,
      builder: (dialogContext) => EditItemDialog(item: item, onSave: onSave),
    );
  }

  /// Shows dialog to add a new item
  static Future<void> showAddDialog(
    BuildContext context,
    Function(KitchenItem) onAdd,
  ) {
    return showDialog(
      context: context,
      builder: (context) => AddItemDialog(onAdd: onAdd),
    );
  }

  /// Shows confirmation dialog for clearing inventory
  static Future<void> showClearConfirmationDialog(
    BuildContext context,
    VoidCallback onConfirm,
  ) {
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clear Inventory'),
            content: const Text(
              'Are you sure you want to delete all items? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onConfirm();
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('CLEAR ALL'),
              ),
            ],
          ),
    );
  }
}
