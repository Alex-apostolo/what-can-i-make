import 'package:flutter/material.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool hasItems;
  final VoidCallback onAddPressed;
  final VoidCallback onClearPressed;

  const HomeAppBar({
    super.key,
    required this.hasItems,
    required this.onAddPressed,
    required this.onClearPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      title: const Text('Kitchen Inventory'),
      actions: [
        if (hasItems)
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear all items',
            onPressed: onClearPressed,
          ),
        IconButton(
          icon: const Icon(Icons.add),
          tooltip: 'Add item manually',
          onPressed: onAddPressed,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
