import 'package:flutter/material.dart';
import '../../../recipes/presentation/recipe_recommendations_screen.dart';
import '../dialogs/image_picker_bottom_sheet.dart';

class InventoryActionButtons extends StatelessWidget {
  final VoidCallback onImagesProcessed;

  const InventoryActionButtons({super.key, required this.onImagesProcessed});

  void _showImagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (modalContext) => ImagePickerBottomSheet(
            onImagesProcessed: onImagesProcessed,
            parentContext: context,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Recipe recommendation button
        FloatingActionButton(
          heroTag: 'recommend_recipes',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RecipeRecommendationsScreen(),
              ),
            );
          },
          backgroundColor: colorScheme.secondaryContainer,
          foregroundColor: colorScheme.onSecondaryContainer,
          tooltip: 'Recipe Recommendations',
          child: const Icon(Icons.restaurant_menu),
        ),
        const SizedBox(width: 16),
        // Camera button
        FloatingActionButton(
          heroTag: 'scan_items',
          onPressed: () => _showImagePicker(context),
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
          tooltip: 'Scan Items',
          child: const Icon(Icons.camera_alt),
        ),
      ],
    );
  }
}
