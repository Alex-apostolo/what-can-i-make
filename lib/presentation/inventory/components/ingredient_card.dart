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
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color: colorScheme.primaryContainer.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: InkWell(
        onTap: () => onEdit(ingredient),
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      ingredient.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${ingredient.quantity} ${ingredient.unitLabel}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              IconButton(
                icon: Icon(
                  Icons.edit_outlined,
                  color: colorScheme.primary,
                  size: 18,
                ),
                onPressed: () => onEdit(ingredient),
                tooltip: 'Edit',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: colorScheme.error,
                  size: 18,
                ),
                onPressed: () => onDelete(ingredient),
                tooltip: 'Delete',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
