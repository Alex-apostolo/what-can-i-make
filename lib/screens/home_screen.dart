import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/storage_service.dart';
import '../models/kitchen_item.dart';
import '../services/openai_service.dart';
import '../widgets/category_section.dart';
import '../widgets/image_picker_bottom_sheet.dart';
import '../widgets/edit_item_dialog.dart';
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

  Future<void> _pickImage(ImageSource source) async {
    final image = await _picker.pickImage(source: source);
    if (image == null) return;

    setState(() => _isLoading = true);
    final result = await _openAIService.analyzeKitchenInventory(image.path);

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

    setState(() {
      _isLoading = false;
    });
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

  @override
  Widget build(BuildContext context) {
    final categories = [
      (
        'Ingredients',
        _inventory.where((item) => item.category == 'ingredient').toList(),
      ),
      (
        'Utensils',
        _inventory.where((item) => item.category == 'utensil').toList(),
      ),
      (
        'Equipment',
        _inventory.where((item) => item.category == 'equipment').toList(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Kitchen Inventory')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadInventory,
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    for (final (title, items) in categories)
                      CategorySection(
                        title: title,
                        items: items,
                        onEdit: _showEditDialog,
                        onDelete: (item) async {
                          final result = await widget.storageService.removeItem(
                            item,
                          );

                          errorHandler.handleEither(
                            result,
                            onSuccess: (_) => _loadInventory(),
                          );
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
                  (context) =>
                      ImagePickerBottomSheet(onImageSourceSelected: _pickImage),
            ),
        child: const Icon(Icons.add_a_photo),
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
