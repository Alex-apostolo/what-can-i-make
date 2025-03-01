import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/storage_service.dart';
import '../models/kitchen_item.dart';
import '../services/openai_service.dart';
import '../widgets/category_section.dart';
import '../widgets/image_picker_bottom_sheet.dart';
import '../widgets/edit_item_dialog.dart';
import '../widgets/add_item_dialog.dart';
import '../core/error/error_handler.dart';

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
    setState(() => _isLoading = true);
    final result = await widget.storageService.getInventory();

    errorHandler.handleEither(
      result,
      onSuccess: (items) {
        setState(() {
          _inventory = items;
        });
      },
    );

    setState(() => _isLoading = false);
  }

  Future<void> _pickImages(ImageSource source) async {
    final images = await _picker.pickMultiImage();
    if (images.isEmpty) return;

    setState(() => _isLoading = true);

    // Process images sequentially
    for (final image in images) {
      await _processImage(image.path);
    }

    setState(() => _isLoading = false);
    return;
  }

  Future<void> _processImage(String imagePath) async {
    final result = await _openAIService.analyzeKitchenInventory(imagePath);

    errorHandler.handleEither(
      result,
      onSuccess: (items) async {
        final saveResult = await widget.storageService.addItems(items);

        errorHandler.handleEither(
          saveResult,
          onSuccess: (_) => _loadInventory(),
        );
      },
    );
  }

  Future<void> _showEditDialog(KitchenItem item) async {
    return showDialog(
      context: context,
      builder:
          (dialogContext) => EditItemDialog(
            item: item,
            onSave: (updatedItem) async {
              final result = await widget.storageService.updateItem(
                updatedItem,
              );

              errorHandler.handleEither(
                result,
                onSuccess: (_) {
                  if (mounted) {
                    _loadInventory();
                  }
                },
              );
            },
          ),
    );
  }

  Future<void> _showAddDialog() async {
    return showDialog(
      context: context,
      builder:
          (context) => AddItemDialog(
            onAdd: (newItem) async {
              final result = await widget.storageService.addItem(newItem);

              errorHandler.handleEither(
                result,
                onSuccess: (_) => _loadInventory(),
              );
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Sort items by ID in reverse order (assuming ID is timestamp-based)
    final sortedInventory = List<KitchenItem>.from(_inventory)
      ..sort((a, b) => b.id.compareTo(a.id));

    final categories = [
      (
        'Ingredients',
        sortedInventory.where((item) => item.category == 'ingredient').toList(),
      ),
      (
        'Utensils',
        sortedInventory.where((item) => item.category == 'utensil').toList(),
      ),
      (
        'Equipment',
        sortedInventory.where((item) => item.category == 'equipment').toList(),
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Kitchen Inventory',
          style: TextStyle(
            color: Color(0xFF424242),
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF424242)),
            tooltip: 'Add item manually',
            onPressed: _showAddDialog,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadInventory,
                child:
                    _inventory.isEmpty
                        ? _buildEmptyState()
                        : ListView(
                          padding: const EdgeInsets.all(16.0),
                          children: [
                            for (final (title, items) in categories)
                              if (items.isNotEmpty)
                                CategorySection(
                                  title: title,
                                  items: items,
                                  onEdit: _showEditDialog,
                                  onDelete: (item) async {
                                    final result = await widget.storageService
                                        .removeItem(item);

                                    errorHandler.handleEither(
                                      result,
                                      onSuccess: (_) => _loadInventory(),
                                    );
                                  },
                                ),
                          ],
                        ),
              ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 10.0),
        child: FloatingActionButton(
          onPressed:
              () => showModalBottomSheet(
                context: context,
                builder:
                    (context) => ImagePickerBottomSheet(
                      onImageSourceSelected: _pickImages,
                    ),
              ),
          tooltip: 'Scan items with camera',
          backgroundColor: const Color(0xFF64B5F6),
          child: const Icon(Icons.add_a_photo, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.kitchen_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Your kitchen inventory is empty',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add items manually or scan with camera',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Item'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7CB342),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
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
