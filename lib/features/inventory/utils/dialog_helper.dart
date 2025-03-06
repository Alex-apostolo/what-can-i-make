import 'package:flutter/material.dart';
import 'package:what_can_i_make/core/models/ingredient.dart';
import 'package:what_can_i_make/features/inventory/presentation/dialogs/add_item_dialog.dart';
import 'package:what_can_i_make/features/inventory/presentation/dialogs/edit_item_dialog.dart';

class DialogHelper {
  /// Shows dialog to edit an item
  static Future<void> showEditDialog(
    BuildContext context,
    Ingredient item,
    Function(Ingredient) onSave,
  ) {
    return showDialog(
      context: context,
      builder:
          (dialogContext) => EditItemDialog(ingredient: item, onEdit: onSave),
    );
  }

  /// Shows dialog to add a new item
  static Future<void> showAddDialog(
    BuildContext context,
    Function(Ingredient) onAdd,
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
