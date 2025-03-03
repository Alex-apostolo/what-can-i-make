import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:what_can_i_make/core/error/error_handler.dart';
import '../../data/repositories/ingredients_repository.dart';
import '../../domain/models/ingredient.dart';
import '../../domain/services/inventory_service.dart';
import '../../domain/services/image_service.dart';
import '../shared/dialog_helper.dart';
import 'components/app_bar.dart';
import 'components/empty_state.dart';
import 'components/loading_indicator.dart';
import 'components/grouped_ingredient_list.dart';
import 'dialogs/image_picker_bottom_sheet.dart';
import '../shared/styled_fab.dart';
import '../recipes/recipe_recommendations_screen.dart';

class InventoryScreen extends StatefulWidget {
  final StorageRepository storageRepository;

  const InventoryScreen({super.key, required this.storageRepository});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  // State variables
  List<Ingredient> _inventory = [];
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
      storageRepository: widget.storageRepository,
    );

    _imageService = ImageService(inventoryService: _inventoryService);

    _loadInventory();
  }

  Future<void> _loadInventory() async {
    setState(() => _isLoading = true);

    final ingredients = errorHandler.handleEither(
      await _inventoryService.getIngredients(),
    );

    setState(() => _inventory = ingredients);
    setState(() => _isLoading = false);
  }

  void _setLoading(bool isLoading) {
    setState(() => _isLoading = isLoading);
  }

  void _pickImages(ImageSource source) async {
    setState(() {
      _isLoading = true;
      _isProcessingImages = true;
      _totalImagesToProcess = 1; // Initial value, will be updated
    });

    if (source == ImageSource.camera) {
      errorHandler.handleEither(
        await _imageService.pickAndProcessCameraImage(),
      );
    } else {
      final pickedResult = errorHandler.handleEither(
        await _imageService.pickAndProcessGalleryImages(),
      );

      if (pickedResult.limitExceeded) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'You selected ${pickedResult.totalSelected} images. Only the first 15 will be processed.',
            ),
            backgroundColor: Colors.orange.shade800,
          ),
        );
      }

      setState(() {
        _totalImagesToProcess = pickedResult.processedCount;
      });
    }

    setState(() {
      _isLoading = false;
      _isProcessingImages = false;
      _totalImagesToProcess = 0;
    });

    // Refresh inventory after processing
    _loadInventory();
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
    DialogHelper.showAddDialog(context, _inventoryService.addIngredient);
  }

  void _showEditDialog(Ingredient item) {
    DialogHelper.showEditDialog(
      context,
      item,
      _inventoryService.updateIngredient,
    );
  }

  void _showClearConfirmationDialog() {
    DialogHelper.showClearConfirmationDialog(context, () {
      _setLoading(true);
      _inventoryService.clearIngredients();
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasItems = _inventory.isNotEmpty;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
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
                        ? GroupedIngredientList(
                          ingredients: _inventory,
                          onEdit: _showEditDialog,
                          onDelete: _inventoryService.deleteIngredient,
                        )
                        : EmptyState(
                          onAddPressed: _showAddDialog,
                          onScanPressed: _showImagePicker,
                        ),
              ),
      floatingActionButton:
          hasItems
              ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Recipe recommendation button
                  FloatingActionButton(
                    heroTag: 'recommend_recipes',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => RecipeRecommendationsScreen(
                                preselectedIngredients: _inventory,
                              ),
                        ),
                      );
                    },
                    backgroundColor: colorScheme.tertiaryContainer,
                    foregroundColor: colorScheme.onTertiaryContainer,
                    tooltip: 'Find Recipes',
                    elevation: 4,
                    child: const Icon(Icons.restaurant_menu, size: 28),
                  ),
                  const SizedBox(width: 16),
                  // Camera button
                  StyledFab(
                    onPressed: _showImagePicker,
                    icon: Icons.add_a_photo_rounded,
                    tooltip: 'Scan items with camera',
                  ),
                ],
              )
              : null,
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
