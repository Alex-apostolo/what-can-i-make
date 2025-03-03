import 'package:flutter/material.dart';
import 'package:what_can_i_make/core/error/error_handler.dart';
import '../../data/repositories/ingredients_repository.dart';
import '../../domain/models/ingredient.dart';
import '../../domain/services/inventory_service.dart';
import '../../domain/services/image_service.dart';
import '../shared/dialog_helper.dart';
import 'components/app_bar.dart';
import 'components/empty_state.dart';
import 'components/grouped_ingredient_list.dart';
import 'dialogs/image_picker_bottom_sheet.dart';
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
    _setLoading(true);

    final ingredients = errorHandler.handleEither(
      await _inventoryService.getIngredients(),
    );

    setInventory(ingredients);
    _setLoading(false);
  }

  void setInventory(List<Ingredient> ingredients) {
    setState(() => _inventory = ingredients);
  }

  void _setLoading(bool isLoading) {
    setState(() => _isLoading = isLoading);
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => ImagePickerBottomSheet(
            imageService: _imageService,
            onImagesProcessed: _loadInventory,
          ),
    );
  }

  void _showAddDialog() {
    DialogHelper.showAddDialog(context, (ingredient) async {
      errorHandler.handleEither(
        await _inventoryService.addIngredients([ingredient]),
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
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [const CircularProgressIndicator()],
                ),
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
                  FloatingActionButton(
                    onPressed: _showImagePicker,
                    tooltip: 'Scan items with camera',
                    elevation: 4,
                    highlightElevation: 8,
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Icon(Icons.add_a_photo_rounded, size: 24.0),
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
