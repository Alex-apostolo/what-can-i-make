import 'package:flutter/material.dart';
import 'ingredient_card.dart';
import 'package:what_can_i_make/core/models/ingredient.dart';
import 'package:what_can_i_make/core/models/ingredient_category.dart';

class GroupedIngredientList extends StatelessWidget {
  final List<Ingredient> ingredients;
  final Function(Ingredient) onEdit;
  final Function(Ingredient) onDelete;

  const GroupedIngredientList({
    super.key,
    required this.ingredients,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Group ingredients by category
    final groupedIngredients = <IngredientCategory, List<Ingredient>>{};

    // Initialize all categories with empty lists
    for (final category in IngredientCategory.values) {
      groupedIngredients[category] = [];
    }

    // Add ingredients to their respective categories
    for (final ingredient in ingredients) {
      groupedIngredients[ingredient.category]!.add(ingredient);
    }

    // Remove empty categories
    groupedIngredients.removeWhere((key, value) => value.isEmpty);

    // Sort categories by their defined sort order
    final sortedCategories =
        groupedIngredients.keys.toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: sortedCategories.length,
      itemBuilder: (context, index) {
        final category = sortedCategories[index];
        final categoryIngredients = groupedIngredients[category]!;

        // Sort ingredients by ID (most recent first)
        // IDs are generated with timestamps, so newer items have higher IDs
        categoryIngredients.sort((a, b) => b.id.compareTo(a.id));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category header
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
              child: Row(
                children: [
                  // Category icon
                  Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Icon(
                      category.icon,
                      color: colorScheme.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Category name
                  Expanded(
                    child: Text(
                      category.displayName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Item count badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Text(
                      '${categoryIngredients.length}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Divider
            Divider(color: colorScheme.primary.withOpacity(0.2)),

            // Ingredients in this category
            ...categoryIngredients.map(
              (ingredient) => IngredientCard(
                ingredient: ingredient,
                onEdit: onEdit,
                onDelete: onDelete,
              ),
            ),

            const SizedBox(height: 8.0),
          ],
        );
      },
    );
  }
}
