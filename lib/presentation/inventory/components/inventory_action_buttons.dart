import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:what_can_i_make/domain/services/inventory_service.dart';
import '../../recipes/recipe_recommendations_screen.dart';
import '../dialogs/image_picker_bottom_sheet.dart';
import '../../../domain/models/ingredient.dart';

class InventoryActionButtons extends StatelessWidget {
  final VoidCallback onImagesProcessed;

  const InventoryActionButtons({super.key, required this.onImagesProcessed});

  void _showImagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
    final inventoryService = context.read<InventoryService>();

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
          backgroundColor: colorScheme.tertiaryContainer,
          foregroundColor: colorScheme.onTertiaryContainer,
          tooltip: 'Find Recipes',
          elevation: 4,
          child: const Icon(Icons.restaurant_menu, size: 28),
        ),
        const SizedBox(width: 16),

        // Camera button
        FloatingActionButton(
          onPressed: () => _showImagePicker(context),
          tooltip: 'Scan items with camera',
          elevation: 4,
          highlightElevation: 8,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: const Icon(Icons.add_a_photo_rounded, size: 24.0),
        ),
      ],
    );
  }
}
