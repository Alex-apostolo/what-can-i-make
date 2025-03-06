import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:what_can_i_make/core/utils/logger.dart';
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

    // Add test button in debug mode
    if (kDebugMode) {
      buttons.insert(
        0,
        FloatingActionButton(
          heroTag: 'test_crashlytics',
          onPressed: _testCrashlytics,
          backgroundColor: colorScheme.errorContainer,
          foregroundColor: colorScheme.onErrorContainer,
          tooltip: 'Test Crashlytics',
          child: const Icon(Icons.bug_report),
        ),
      );
      buttons.insert(1, const SizedBox(width: 16));
    }

    return Row(mainAxisSize: MainAxisSize.min, children: buttons);
  }

  void _testCrashlytics() {
    final logger = AppLogger();
    logger.i('Testing Crashlytics...');

    // Option 1: Log a non-fatal error
    try {
      throw Exception('Test exception for Crashlytics');
    } catch (e, stack) {
      logger.e('Caught test exception', error: e, stackTrace: stack);
    }

    // Option 2: Force a crash (uncomment to test)
    // FirebaseCrashlytics.instance.crash();
  }
}
