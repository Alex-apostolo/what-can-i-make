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
      _isProcessingImages = true;
      _totalImagesToProcess = 0;
    });

    try {
      // Pick images based on source
      if (source == ImageSource.camera) {
        await _handleCameraImage();
      } else {
        await _handleGalleryImages();
      }

      // Refresh inventory after successful processing
      await _loadInventory();
    } finally {
      // Always reset processing state
      setState(() {
        _isLoading = false;
        _isProcessingImages = false;
        _totalImagesToProcess = 0;
      });
    }
  }

  // Handle camera image selection and processing
  Future<void> _handleCameraImage() async {
    final image = errorHandler.handleEither(
      await _imageService.pickCameraImage(),
    );

    // Exit if user cancelled
    if (image == null) return;

    // Process the image
    setState(() {
      _totalImagesToProcess = 1;
      _isLoading = true;
    });
    await errorHandler.handleEither(await _imageService.processImage(image));
  }

  // Handle gallery images selection and processing
  Future<void> _handleGalleryImages() async {
    final pickedImages = errorHandler.handleEither(
      await _imageService.pickGalleryImages(),
    );

    // Exit if no images were selected
    if (pickedImages.isEmpty) return;

    // Show warning if too many images
    if (pickedImages.limitExceeded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You selected ${pickedImages.totalSelected} images. Only the first 15 will be processed.',
          ),
          backgroundColor: Colors.orange.shade800,
        ),
      );
    }

    // Process the images
    setState(() {
      _totalImagesToProcess = pickedImages.count;
      _isLoading = true;
    });
    await errorHandler.handleEither(
      await _imageService.processImages(pickedImages.images),
    );
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
    DialogHelper.showAddDialog(context, (ingredient) async {
      errorHandler.handleEither(
        await _inventoryService.addIngredient(ingredient),
      );
      _loadInventory();
    });
  }

  void _showEditDialog(Ingredient item) {
    DialogHelper.showEditDialog(context, item, (updatedIngredient) async {
      errorHandler.handleEither(
        await _inventoryService.updateIngredient(updatedIngredient),
      );
      _loadInventory();
    });
  }

  void _showClearConfirmationDialog() {
    DialogHelper.showClearConfirmationDialog(context, () async {
      _setLoading(true);
      errorHandler.handleEither(await _inventoryService.clearIngredients());
      _loadInventory();
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
                          onDelete: (ingredient) async {
                            errorHandler.handleEither(
                              await _inventoryService.deleteIngredient(
                                ingredient,
                              ),
                            );
                            _loadInventory();
                          },
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
