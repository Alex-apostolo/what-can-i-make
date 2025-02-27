import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/storage_service.dart';
import '../models/kitchen_item.dart';
import '../services/openai_service.dart';
import '../components/category_section.dart';
import '../components/image_picker_bottom_sheet.dart';

class HomeScreen extends StatefulWidget {
  final StorageService storageService;

  const HomeScreen({super.key, required this.storageService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<KitchenItem> _inventory = [];
  bool _isLoading = true;
  final _picker = ImagePicker();
  final _openAIService = OpenAIService();

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    if (!mounted) return;
    try {
      setState(() => _isLoading = true);
      _inventory = await widget.storageService.getInventory();
      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('Error loading inventory: $e');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (!mounted) return;
    try {
      final image = await _picker.pickImage(source: source);
      if (image == null || !mounted) return;

      setState(() => _isLoading = true);
      final items = await _openAIService.analyzeKitchenInventory(image.path);
      await widget.storageService.addItems(items);

      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSuccess('Successfully added ${items.length} items');
      _loadInventory();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('Error processing image. Please try again.');
    }
  }

  void _showError(String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showSuccess(String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
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
                    CategorySection(
                      title: 'Ingredients',
                      items: ingredients,
                      onEdit: _showEditDialog,
                      onDelete: (item) async {
                        await widget.storageService.removeItem(item);
                        _loadInventory();
                      },
                    ),
                    CategorySection(
                      title: 'Utensils',
                      items: utensils,
                      onEdit: _showEditDialog,
                      onDelete: (item) async {
                        await widget.storageService.removeItem(item);
                        _loadInventory();
                      },
                    ),
                    CategorySection(
                      title: 'Equipment',
                      items: equipment,
                      onEdit: _showEditDialog,
                      onDelete: (item) async {
                        await widget.storageService.removeItem(item);
                        _loadInventory();
                      },
                    ),
                  ],
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed:
            () => showModalBottomSheet(
              context: context,
              builder:
                  (context) => ImagePickerBottomSheet(
                    onImageSourceSelected: (source) => _pickImage(source),
                  ),
            ),
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }

  Future<void> _showEditDialog(KitchenItem item) async {
    final nameController = TextEditingController(text: item.name);
    final quantityController = TextEditingController(text: item.quantity);

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Item'),
            content: Column(
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
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  final updatedItem = item.copyWith(
                    name: nameController.text,
                    quantity: quantityController.text,
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
  void dispose() {
    _openAIService.dispose();
    widget.storageService.close();
    super.dispose();
  }
}
