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
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: ingredients.length,
      itemBuilder: (context, index) {
        return IngredientCard(
          ingredient: ingredients[index],
          onEdit: onEdit,
          onDelete: onDelete,
        );
      },
    );
  }
}
