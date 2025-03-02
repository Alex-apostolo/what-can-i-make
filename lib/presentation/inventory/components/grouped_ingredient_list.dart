import 'package:flutter/material.dart';
import '../../../domain/models/ingredient.dart';
import '../../../domain/models/ingredient_category.dart';
import 'ingredient_card.dart';

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
    
    // Sort categories by display name
    final sortedCategories = groupedIngredients.keys.toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: sortedCategories.length,
      itemBuilder: (context, index) {
        final category = sortedCategories[index];
        final categoryIngredients = groupedIngredients[category]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category header
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
              child: Text(
                category.displayName,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            // Divider
            Divider(color: colorScheme.primary.withOpacity(0.2)),
            
            // Ingredients in this category
            ...categoryIngredients.map((ingredient) => IngredientCard(
              ingredient: ingredient,
              onEdit: onEdit,
              onDelete: onDelete,
            )),
            
            const SizedBox(height: 8.0),
          ],
        );
      },
    );
  }
} 