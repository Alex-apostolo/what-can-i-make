import 'package:flutter/material.dart';
import 'package:what_can_i_make/features/recipes/presentation/recipe_recommendations_screen.dart';

class InventoryActionButtons extends StatelessWidget {
  final VoidCallback onImagesProcessed;
  final VoidCallback showImagePicker;

  const InventoryActionButtons({
    super.key,
    required this.onImagesProcessed,
    required this.showImagePicker,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final buttons = <Widget>[
      // Recipe recommendation button
      FloatingActionButton(
        heroTag: 'recommend_recipes',
        onPressed: () {
          Navigator.pushNamed(context, RecipeRecommendationsScreen.routeName);
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
        onPressed: showImagePicker,
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        tooltip: 'Scan Items',
        child: const Icon(Icons.camera_alt),
      ),
    ];

    return Row(mainAxisSize: MainAxisSize.min, children: buttons);
  }
}
