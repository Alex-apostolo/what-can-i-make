import 'package:flutter/material.dart';
import '../../../domain/models/ingredient.dart';
import '../../../core/utils/generate_unique_id.dart';
import '../../../domain/models/measurement_unit.dart';

class AddItemDialog extends StatefulWidget {
  final Function(Ingredient) onAdd;

  const AddItemDialog({super.key, required this.onAdd});

  @override
  State<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  MeasurementUnit _selectedUnit = MeasurementUnit.piece;

  @override
  void initState() {
    super.initState();
    // Set default unit
    _selectedUnit = MeasurementUnit.piece;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _handleAdd() {
    if (_formKey.currentState!.validate()) {
      final int quantity = int.tryParse(_quantityController.text) ?? 0;
      final newItem = Ingredient(
        id: generateUniqueIdWithTimestamp(),
        name: _nameController.text,
        quantity: quantity,
        unit: MeasurementUnit.fromString(_selectedUnit.label),
      );

      widget.onAdd(newItem);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Text(
        'Add Ingredient',
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
          onPressed: _handleAdd,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
          ),
          child: const Text('ADD'),
        ),
      ],
    );
  }
}
