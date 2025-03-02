import 'package:flutter/material.dart';
import '../../../domain/models/ingredient.dart';

class IngredientCard extends StatelessWidget {
  final Ingredient ingredient;
  final Function(Ingredient) onEdit;
  final Function(Ingredient) onDelete;

  const IngredientCard({
    super.key,
    required this.ingredient,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(
          color: colorScheme.primaryContainer.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => onEdit(ingredient),
        borderRadius: BorderRadius.circular(16.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row with name and actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Name with category icon
                  Expanded(
                    child: Row(
                      children: [
                        // Category icon
                        Container(
                          padding: const EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withOpacity(
                              0.3,
                            ),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Icon(
                            ingredient.category.icon,
                            color: colorScheme.primary,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Ingredient name
                        Expanded(
                          child: Text(
                            ingredient.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Action buttons
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.edit_outlined,
                          color: colorScheme.primary,
                          size: 22,
                        ),
                        onPressed: () => onEdit(ingredient),
                        tooltip: 'Edit',
                        style: IconButton.styleFrom(
                          backgroundColor: colorScheme.primaryContainer
                              .withOpacity(0.2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: colorScheme.error,
                          size: 22,
                        ),
                        onPressed: () => onDelete(ingredient),
                        tooltip: 'Delete',
                        style: IconButton.styleFrom(
                          backgroundColor: colorScheme.errorContainer
                              .withOpacity(0.2),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Quantity badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 6.0,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withOpacity(0.1),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  '${ingredient.quantity} ${ingredient.unitLabel}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
