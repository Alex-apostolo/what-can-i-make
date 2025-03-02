import 'package:flutter/material.dart';
import '../../../domain/models/ingredient.dart';
import '../../../domain/models/measurement_unit.dart';
import '../../../domain/models/ingredient_category.dart';
import '../../../domain/services/category_service.dart';
import '../../../core/error/error_handler.dart';

class EditItemDialog extends StatefulWidget {
  final Ingredient ingredient;
  final Function(Ingredient) onEdit;

  const EditItemDialog({
    super.key,
    required this.ingredient,
    required this.onEdit,
  });

  @override
  State<EditItemDialog> createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<EditItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late MeasurementUnit _selectedUnit;
  bool _isLoading = false;
  bool _nameChanged = false;
  final _categoryService = CategoryService();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.ingredient.name);
    _quantityController = TextEditingController(
      text: widget.ingredient.quantity.toString(),
    );
    _selectedUnit = widget.ingredient.unit;

    // Listen for name changes to trigger recategorization
    _nameController.addListener(() {
      if (_nameController.text != widget.ingredient.name) {
        setState(() => _nameChanged = true);
      } else {
        setState(() => _nameChanged = false);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _categoryService.dispose();
    super.dispose();
  }

  Future<void> _handleEdit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final int quantity = int.tryParse(_quantityController.text) ?? 0;
      final name = _nameController.text;

      // Only recategorize if the name has changed
      IngredientCategory category = widget.ingredient.category;
      if (_nameChanged) {
        // Get category from CategoryService
        final categoryResult = await _categoryService.categorizeIngredient(
          name,
        );

        category = categoryResult.fold((failure) {
          // If there's an error, use the default category
          errorHandler.handleFailure(failure);
          return IngredientCategory.other;
        }, (category) => category);
      }

      setState(() => _isLoading = false);

      final updatedItem = widget.ingredient.copyWith(
        name: name,
        quantity: quantity,
        unit: _selectedUnit,
        category: category,
      );

      widget.onEdit(updatedItem);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Text(
        'Edit Ingredient',
        style: TextStyle(color: colorScheme.primary),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.restaurant),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.sentences,
              ),
              if (_nameChanged)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Changing the name will recategorize the ingredient',
                    style: TextStyle(
                      color: colorScheme.secondary,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  prefixIcon: Icon(Icons.numbers),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Invalid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<MeasurementUnit>(
                value: _selectedUnit,
                decoration: const InputDecoration(
                  labelText: 'Unit',
                  prefixIcon: Icon(Icons.scale),
                ),
                items:
                    MeasurementUnit.values.map((unit) {
                      return DropdownMenuItem<MeasurementUnit>(
                        value: unit,
                        child: Text(unit.displayName),
                      );
                    }).toList(),
                onChanged: (MeasurementUnit? newValue) {
                  setState(() {
                    _selectedUnit = newValue ?? MeasurementUnit.piece;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Display current category
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _nameChanged
                          ? Icons.category
                          : widget.ingredient.category.icon,
                      color: colorScheme.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Category',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _nameChanged
                                ? 'Will be updated on save'
                                : widget.ingredient.category.displayName,
                            style: TextStyle(
                              color:
                                  _nameChanged
                                      ? colorScheme.secondary
                                      : colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('CANCEL', style: TextStyle(color: colorScheme.secondary)),
        ),
        _isLoading
            ? const CircularProgressIndicator()
            : ElevatedButton(
              onPressed: _handleEdit,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
              child: const Text('SAVE'),
            ),
      ],
    );
  }
}
