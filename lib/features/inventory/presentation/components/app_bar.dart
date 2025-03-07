import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:what_can_i_make/features/user/presentation/account_screen.dart';

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 2,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Kitchen Inventory',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
        ],
      ),
      centerTitle: true,
      leading:
          hasItems
              ? IconButton(
                icon: const FaIcon(FontAwesomeIcons.trashCan, size: 18),
                tooltip: 'Clear all items',
                onPressed: onClearPressed,
                style: IconButton.styleFrom(
                  foregroundColor: colorScheme.error,
                  backgroundColor: colorScheme.errorContainer.withOpacity(0.2),
                ),
              )
              : null,
      actions: [
        if (hasItems)
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.circlePlus, size: 18),
            tooltip: 'Add item manually',
            onPressed: onAddPressed,
            style: IconButton.styleFrom(
              foregroundColor: colorScheme.primary,
              backgroundColor: colorScheme.primaryContainer.withOpacity(0.2),
            ),
          ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.account_circle),
          tooltip: 'Account',
          onPressed: () {
            Navigator.of(context).pushNamed(AccountScreen.routeName);
          },
          style: IconButton.styleFrom(
            foregroundColor: colorScheme.onSurface,
            backgroundColor: colorScheme.surfaceVariant.withOpacity(0.2),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
