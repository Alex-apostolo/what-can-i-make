import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/openai_service.dart';

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
    setState(() => _isLoading = true);
    final items = await widget.storageService.getInventory();
    setState(() {
      _inventory = items;
      _isLoading = false;
    });
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
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      await widget.storageService.removeItem(item);
                      _loadInventory();
                    },
                  ),
                ),
              );
            },
          ),
      ],
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
