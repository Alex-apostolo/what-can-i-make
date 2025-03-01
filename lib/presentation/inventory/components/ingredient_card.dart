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

    return InkWell(
      onTap: () => onEdit(ingredient),
      borderRadius: BorderRadius.circular(12.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ingredient.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4.0),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 2.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: Colors.green.shade200,
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      '${ingredient.quantity} ${ingredient.unit}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Actions
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => onEdit(ingredient),
                  tooltip: 'Edit',
                  iconSize: 20.0,
                  color: theme.colorScheme.primary,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => onDelete(ingredient),
                  tooltip: 'Delete',
                  iconSize: 20.0,
                  color: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
