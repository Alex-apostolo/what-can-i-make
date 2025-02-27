import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../models/kitchen_item.dart';

class HomeScreen extends StatefulWidget {
  final StorageService storageService;

  const HomeScreen({super.key, required this.storageService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<KitchenItem> _inventory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    try {
      setState(() => _isLoading = true);
      final items = await widget.storageService.getInventory();
      if (mounted) {
        setState(() {
          _inventory = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading inventory: $e')));
      }
      print('Error loading inventory: $e');
    }
  }

  Widget _buildCategorySection(String title, List<KitchenItem> items) {
    return ExpansionTile(
      title: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      initiallyExpanded: true,
      children: [
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('No items found'),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                child: ListTile(
                  title: Text(item.name),
                  subtitle:
                      item.quantity != null || item.notes != null
                          ? Text(
                            [
                              if (item.quantity != null)
                                'Quantity: ${item.quantity}',
                              if (item.notes != null) 'Notes: ${item.notes}',
                            ].join('\n'),
                          )
                          : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showEditDialog(item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          await widget.storageService.removeItem(item);
                          _loadInventory();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Future<void> _showEditDialog(KitchenItem item) async {
    final TextEditingController nameController = TextEditingController(
      text: item.name,
    );
    final TextEditingController quantityController = TextEditingController(
      text: item.quantity,
    );
    final TextEditingController notesController = TextEditingController(
      text: item.notes,
    );

    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Item'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  TextField(
                    controller: quantityController,
                    decoration: const InputDecoration(labelText: 'Quantity'),
                  ),
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(labelText: 'Notes'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  final updatedItem = KitchenItem(
                    id: item.id,
                    name: nameController.text,
                    category: item.category,
                    quantity:
                        quantityController.text.isEmpty
                            ? null
                            : quantityController.text,
                    notes:
                        notesController.text.isEmpty
                            ? null
                            : notesController.text,
                  );

                  await widget.storageService.updateItem(updatedItem);
                  if (mounted) {
                    Navigator.pop(context);
                    _loadInventory();
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ingredients =
        _inventory.where((item) => item.category == 'ingredient').toList();
    final utensils =
        _inventory.where((item) => item.category == 'utensil').toList();
    final equipment =
        _inventory.where((item) => item.category == 'equipment').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kitchen Inventory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInventory,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadInventory,
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    _buildCategorySection('Ingredients', ingredients),
                    _buildCategorySection('Utensils', utensils),
                    _buildCategorySection('Equipment', equipment),
                  ],
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/add-items');
          if (result == true) {
            _loadInventory();
          }
        },
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }

  @override
  void dispose() {
    widget.storageService.close();
    super.dispose();
  }
}
