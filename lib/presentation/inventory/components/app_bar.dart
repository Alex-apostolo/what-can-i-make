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
      backgroundColor: Colors.white,
      title: const Text(
        'Kitchen Inventory',
        style: TextStyle(
          color: Color(0xFF424242),
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        if (hasItems)
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Color(0xFF424242)),
            tooltip: 'Clear all items',
            onPressed: onClearPressed,
          ),
        IconButton(
          icon: const Icon(Icons.add, color: Color(0xFF424242)),
          tooltip: 'Add item manually',
          onPressed: onAddPressed,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
} 