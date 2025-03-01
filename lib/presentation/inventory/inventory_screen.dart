import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/repositories/storage_repository.dart';
import '../../domain/models/kitchen_item.dart';
import '../../domain/services/inventory_service.dart';
import '../../domain/services/image_service.dart';
import '../shared/dialog_helper.dart';
import 'components/app_bar.dart';
import 'components/empty_state.dart';
import 'components/loading_indicator.dart';
import 'components/inventory_list.dart';
import 'dialogs/image_picker_bottom_sheet.dart';
import '../shared/styled_fab.dart';

class InventoryScreen extends StatefulWidget {
  final StorageRepository storageRepository;

  const InventoryScreen({super.key, required this.storageRepository});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  // State variables
  List<KitchenItem> _inventory = [];
  bool _isLoading = true;
  bool _isProcessingImages = false;
  int _totalImagesToProcess = 0;

  // Services
  late final InventoryService _inventoryService;
  late final ImageService _imageService;

  @override
  void initState() {
    super.initState();

    // Initialize services
    _inventoryService = InventoryService(
      onInventoryChanged: _loadInventory,
      storageRepository: widget.storageRepository,
    );

    _imageService = ImageService(
      onInventoryChanged: _loadInventory,
      storageRepository: widget.storageRepository,
    );

    _loadInventory();
  }

  Future<void> _loadInventory() async {
    setState(() => _isLoading = true);

    final items = await _inventoryService.loadInventory();
    setState(() => _inventory = items);

    setState(() => _isLoading = false);
  }

  void _setLoading(bool isLoading) {
    setState(() => _isLoading = isLoading);
  }

  void _setProcessingImages(bool isProcessing, int count) {
    setState(() {
      _isProcessingImages = isProcessing;
      _totalImagesToProcess = count;
    });
  }

  void _pickImages(ImageSource source) {
    _imageService.pickImages(
      context,
      source,
      _setLoading,
      _setProcessingImages,
    );
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => ImagePickerBottomSheet(
            onCameraTap: () {
              Navigator.pop(context);
              _pickImages(ImageSource.camera);
            },
            onGalleryTap: () {
              Navigator.pop(context);
              _pickImages(ImageSource.gallery);
            },
          ),
    );
  }

  void _showAddDialog() {
    DialogHelper.showAddDialog(context, _inventoryService.addItem);
  }

  void _showEditDialog(KitchenItem item) {
    DialogHelper.showEditDialog(context, item, _inventoryService.updateItem);
  }

  void _showClearConfirmationDialog() {
    DialogHelper.showClearConfirmationDialog(context, () {
      _setLoading(true);
      _inventoryService.clearInventory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final categories = _inventoryService.categorizeInventory(_inventory);
    final hasItems = _inventory.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: HomeAppBar(
        hasItems: hasItems,
        onAddPressed: _showAddDialog,
        onClearPressed: _showClearConfirmationDialog,
      ),
      body:
          _isLoading
              ? LoadingIndicator(
                isProcessingImages: _isProcessingImages,
                imageCount: _totalImagesToProcess,
              )
              : RefreshIndicator(
                onRefresh: _loadInventory,
                child:
                    hasItems
                        ? InventoryList(
                          categories: categories,
                          onEdit: _showEditDialog,
                          onDelete: _inventoryService.deleteItem,
                        )
                        : EmptyState(onAddPressed: _showAddDialog),
              ),
      floatingActionButton: StyledFab(
        onPressed: _showImagePicker,
        icon: Icons.add_a_photo_rounded,
        tooltip: 'Scan items with camera',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  @override
  void dispose() {
    _inventoryService.dispose();
    _imageService.dispose();
    super.dispose();
  }
}
