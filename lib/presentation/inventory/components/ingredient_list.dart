import 'package:flutter/material.dart';
import '../../../domain/models/ingredient.dart';
import 'ingredient_card.dart';

class IngredientList extends StatelessWidget {
  final List<Ingredient> ingredients;
  final Function(Ingredient) onEdit;
  final Function(Ingredient) onDelete;

  const IngredientList({
    super.key,
    required this.ingredients,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: ingredients.length,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12.0),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IngredientCard(
            ingredient: ingredients[index],
            onEdit: onEdit,
            onDelete: onDelete,
          ),
        );
      },
    );
  }
}
