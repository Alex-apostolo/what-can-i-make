import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class EmptyState extends StatelessWidget {
  final VoidCallback onAddPressed;
  final VoidCallback? onScanPressed;

  const EmptyState({super.key, required this.onAddPressed, this.onScanPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration container
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  FaIcon(
                    FontAwesomeIcons.kitchenSet,
                    size: 80,
                    color: colorScheme.primary.withOpacity(0.8),
                  ),
                  Positioned(
                    top: 50,
                    right: 50,
                    child: FaIcon(
                      FontAwesomeIcons.utensils,
                      size: 30,
                      color: colorScheme.secondary.withOpacity(0.7),
                    ),
                  ),
                  Positioned(
                    bottom: 50,
                    left: 50,
                    child: FaIcon(
                      FontAwesomeIcons.basketShopping,
                      size: 30,
                      color: colorScheme.tertiary.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            Text(
              'Your Kitchen Inventory is Empty',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onBackground,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              'Start adding items to keep track of your kitchen inventory',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onBackground.withOpacity(0.7),
              ),
            ),

            const SizedBox(height: 40),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ActionButton(
                  onPressed: onAddPressed,
                  icon: FontAwesomeIcons.circlePlus,
                  label: 'Add Item',
                  color: colorScheme.primary,
                ),

                if (onScanPressed != null) ...[
                  const SizedBox(width: 16),
                  _ActionButton(
                    onPressed: onScanPressed!,
                    icon: FontAwesomeIcons.barcode,
                    label: 'Scan Items',
                    color: colorScheme.secondary,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color color;

  const _ActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contrastColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
            ? Colors.white
            : Colors.black87;

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: contrastColor,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        shadowColor: color.withOpacity(0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, color: contrastColor, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(
              color: contrastColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
