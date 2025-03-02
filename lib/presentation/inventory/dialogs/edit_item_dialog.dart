import 'package:flutter/material.dart';
import '../../../domain/models/ingredient.dart';
import '../../../domain/models/measurement_unit.dart';

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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.ingredient.name);
    _quantityController = TextEditingController(
      text: widget.ingredient.quantity.toString(),
    );
    _selectedUnit = widget.ingredient.unit;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _handleEdit() {
    if (_formKey.currentState!.validate()) {
      final int quantity = int.tryParse(_quantityController.text) ?? 0;
      final updatedItem = widget.ingredient.copyWith(
        name: _nameController.text,
        quantity: quantity,
        unit: _selectedUnit,
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
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('CANCEL', style: TextStyle(color: colorScheme.secondary)),
        ),
        ElevatedButton(
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
